import 'package:flutter/material.dart';

IconData achievementIconAsset(String iconKey) => switch (iconKey) {
  'person_add' => Icons.person_add_alt_1_rounded,
  'air' => Icons.air_rounded,
  'grid_on' => Icons.grid_on_rounded,
  'palette' => Icons.palette_rounded,
  'self_improvement' => Icons.self_improvement_rounded,
  'menu_book' => Icons.menu_book_rounded,
  'task_alt' => Icons.task_alt_rounded,
  'water_drop' => Icons.water_drop_rounded,
  'sort_by_alpha' => Icons.sort_by_alpha_rounded,
  'blur_on' => Icons.blur_on_rounded,
  'favorite_border' => Icons.favorite_border_rounded,
  _ => Icons.auto_awesome_rounded,
};
