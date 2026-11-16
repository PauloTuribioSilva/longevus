# longevus_app

App Flutter do Longevus (frontend).

## Setup

Depois de clonar ou puxar alterações, rode sempre:

```
flutter pub get
```

> Atenção: foi adicionada a dependência `google_fonts` ao `pubspec.yaml` para a nova identidade visual (fonte Plus Jakarta Sans). Se o app não buildar com erro de pacote não encontrado, rode o comando acima antes de qualquer outra coisa.

## Design

A UI usa um design system centralizado em `lib/core/theme/app_theme.dart` (paleta roxo/dourado, raios, sombras suaves, tipografia) e componentes reutilizáveis em `lib/core/widgets/` (`PremiumMenuCard`, `SectionLabel`, `EmptyState`, `SoftCard`, `PhotoPickerAvatar`). Novas telas devem reaproveitar esses componentes e os tokens de `AppTheme` em vez de estilizar widgets do zero.

As mudanças visuais foram revisadas manualmente (chaves/parênteses balanceados, membros de `AppTheme` conferidos) mas ainda não foram validadas com `flutter run` nesta máquina por falta do SDK instalado — vale testar no ambiente de quem for buildar.
