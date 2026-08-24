import 'package:flutter/widgets.dart';

/// A partir daqui o app troca a tab bar inferior pela sidebar fixa e usa os
/// layouts largos do handoff (telas 13–17, desenhadas em 1280×800).
const double kDesktopBreakpoint = 900;

/// Largura da sidebar no layout desktop.
const double kSidebarWidth = 240;

/// Limite de tamanho aceito pelo seletor de arquivos, conforme a copy da tela
/// de conversão ("até 25MB").
const int kMaxUploadBytes = 25 * 1024 * 1024;

/// Extensões que a tela de conversão aceita -- tudo que o LibreOffice
/// exporta para PDF sem perda estrutural: Word, Excel e PowerPoint, nos
/// formatos binário (97-2003) e OOXML.
const List<String> kConvertibleExtensions = [
  'doc', 'docx',
  'xls', 'xlsx',
  'ppt', 'pptx',
];

/// [kConvertibleExtensions] em caixa alta, para a mensagem de erro quando o
/// arquivo escolhido não é suportado.
const String kConvertibleExtensionsLabel = 'DOC, DOCX, XLS, XLSX, PPT ou PPTX';

/// Nomes dos apps de origem, para textos curtos como a legenda da dropzone
/// ("Word, Excel ou PowerPoint, até 25MB").
const String kConvertibleAppsLabel = 'Word, Excel ou PowerPoint';

/// Versão exibida no Perfil. Precisa acompanhar `version:` do pubspec.yaml.
const String kAppVersion = '1.0.0';

extension LayoutX on BuildContext {
  /// `true` quando a janela é larga o bastante para o layout de desktop.
  bool get isDesktop =>
      MediaQuery.sizeOf(this).width >= kDesktopBreakpoint;
}
