# shared_preferences_android 2.5+ usa Pigeon JNI: o Dart procura classes e métodos
# Java/Kotlin pelo nome e pela assinatura exata. O plugin não traz regras próprias,
# e o R8 do build de release renomeia esses tipos (ex.: kotlin.coroutines.Continuation
# vira "x0.c"), o que causa NoSuchMethodError ao ler a sessão salva.
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Tipos do Kotlin que aparecem nas assinaturas chamadas via JNI (funções suspend).
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$* { *; }
-keep class kotlin.Unit { *; }
