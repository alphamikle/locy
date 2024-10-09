import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import '../gen/generator_config.dart';
import '../tools/log.dart';
import '../type/mappers.dart';
import '../type/types.dart';
import 'content_loader.dart';
import 'language_localization.dart';
import 'pubspec_loader.dart';

const kFlutter = 'flutter';
const kAssets = 'assets';
const kDependencies = 'dependencies';
const kIntl = 'intl';
const kEnv = 'environment';
const kSdk = 'sdk';

/// Used to load localizations in the generation-based flow
class AssetsGenLoader implements ContentLoader {
  AssetsGenLoader(this.config);

  final GeneratorConfig config;

  late YamlMap _pubspecContent;

  YamlMap? get _dependencies => _pubspecContent[kDependencies];

  String? get intlVersion => _dependencies == null ? null : _dependencies![kIntl];

  String? get dartSdk => _pubspecContent[kEnv][kSdk];

  @override
  List<LanguageLocalization> load() {
    _pubspecContent = PubspecLoader().load();
    final YamlMap? flutter = _pubspecContent[kFlutter];
    if (flutter == null) {
      throw Exception('Not found "flutter" section in pubspec.yaml');
    }
    final YamlList? assets = flutter[kAssets];
    if (assets == null || assets.isEmpty) {
      throw Exception('''
Not found "assets" section in the pubspec.yaml file or this section is empty. Please, add at least one folder to assets section like that:
# pubspec.yaml
#...
flutter:
  #...
  assets: <-- 1
    - assets/ <-- 2 # or name of your assets folder
#...
''');
    }
    final Map<String, LanguageLocalization> localizationsCache = {};
    final List<LanguageLocalization> result = [];

    for (final dynamic asset in assets) {
      if (asset is String) {
        final String dirPath = join(Directory.current.path, asset);
        final (List<File> matchedFiles, List<LanguageLocalization> localizations) = _scanDir(Directory(dirPath));
        for (int i = 0; i < matchedFiles.length; i++) {
          final File file = matchedFiles[i];
          final LanguageLocalization localization = localizations[i];
          localizationsCache[file.path] = localization;
        }
      }
    }

    for (final MapEntry(:value) in localizationsCache.entries) {
      result.add(value);
    }

    return result;
  }

  (List<File>, List<LanguageLocalization>) _scanDir(Directory directory) {
    final List<LanguageLocalization> localizationFiles = [];
    final List<File> matchedFiles = [];
    final List<File> allFiles = directory.listSync(recursive: true).whereType<File>().toList();
    for (final File file in allFiles) {
      bool isExcluded = false;
      String? exclusionPattern;
      for (final String excludedPattern in config.excludedPatterns) {
        final RegExp excludedRegExp = RegExp(excludedPattern);

        isExcluded = excludedRegExp.hasMatch(file.path);
        if (isExcluded) {
          exclusionPattern = excludedPattern;
          break;
        }
      }
      if (isExcluded) {
        logOnce('[EASIEST_LOCALIZATION] File "${file.path}" was excluded from generation by pattern "$exclusionPattern"');
        continue;
      }
      final RegExpMatch? match = config.regExp.firstMatch(file.path);

      if (match != null) {
        final String? language = match.namedGroup('lang');

        if (language == null || language.length != 2) {
          throw Exception('Language code "$language" is not valid');
        }

        String? country;

        try {
          country = match.namedGroup('country');
        } catch (error) {
          log('Error on getting country from the RegExp(${config.regExp.toString()})');
        }

        final String rawContent = file.readAsStringSync();
        if (rawContent.isEmpty) {
          logOnce('[EASIEST_LOCALIZATION] File "${file.path}" have no localization content');
          continue;
        }
        final Json content = yamlMapToJson(loadYaml(rawContent));
        localizationFiles.add(LanguageLocalization(language: language.toLowerCase(), country: country?.toUpperCase(), content: content));
        matchedFiles.add(file);
      }
    }
    return (matchedFiles, localizationFiles);
  }
}
