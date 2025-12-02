import 'package:flutter/material.dart';

// Extensión para agregar soporte para headline5 en temas modernos
extension TextThemeCompat on TextTheme {
  TextStyle get headline5 => titleLarge ?? const TextStyle(fontSize: 20);
}

// Función para reemplazar hashValues
int hashValues(dynamic a, dynamic b) {
  return Object.hash(a, b);
} 