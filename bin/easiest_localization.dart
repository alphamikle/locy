import 'package:easiest_localization/src/gen/generator.dart';
import 'package:easiest_localization/src/gen/generator_config.dart';
import 'package:easiest_localization/src/loader/config_loader.dart';
import 'package:easiest_localization/src/loader/language_localization.dart';
import 'package:intl/intl.dart';

String _locales(int howMany) => Intl.plural(
      howMany,
      name: 'locales',
      one: 'locale',
      other: 'locales',
    );

void main(List<String> args) {
  final int start = DateTime.now().millisecondsSinceEpoch;
  GeneratorConfig config = ConfigLoader().load();
  if (args.contains('--format')) {
    config = config.copyWith(formatOutput: true);
  }
  final Generator generator = Generator(config);
  final (String, List<LanguageLocalization>) result = generator.generate();
  final int end = (DateTime.now().millisecondsSinceEpoch - start);

  final List<String> locales = result.$2.map((LanguageLocalization it) => it.name).toList(growable: false);

  // ignore: avoid_print
  print('[EASIEST_LOCALIZATION] Localizations generation completed in ${end}ms with [${locales.join(', ')}] ${_locales(locales.length)}');
}
