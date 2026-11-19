import 'package:flutter/material.dart';

import 'theme.dart';

class MoneyCategory {
  final String name;
  final IconData icon;
  final Color color;
  const MoneyCategory(this.name, this.icon, this.color);
}

/// Kategori pengeluaran (layar Expense & chatbot).
const expenseCategories = <MoneyCategory>[
  MoneyCategory('Food', Icons.restaurant_rounded, AppColors.kuning),
  MoneyCategory('Transport', Icons.directions_bus_rounded, AppColors.tosca),
  MoneyCategory('Shopping', Icons.shopping_bag_rounded, AppColors.ungu),
  MoneyCategory('Bills', Icons.receipt_long_rounded, AppColors.unguTua),
  MoneyCategory('Fun', Icons.star_rounded, AppColors.pink),
  MoneyCategory('Gift', Icons.card_giftcard_rounded, AppColors.ungu),
  MoneyCategory('Study', Icons.school_rounded, AppColors.tosca),
  MoneyCategory('Other', Icons.more_horiz_rounded, AppColors.muted),
];

/// Sumber pemasukan (layar Top Up & chatbot).
const incomeSources = <MoneyCategory>[
  MoneyCategory('Salary', Icons.work_rounded, AppColors.tosca),
  MoneyCategory('Allowance', Icons.card_giftcard_rounded, AppColors.ungu),
  MoneyCategory('Side hustle', Icons.storefront_rounded, AppColors.kuning),
  MoneyCategory('Found on street', Icons.place_rounded, AppColors.unguTua),
  MoneyCategory('Falling from heaven', Icons.cloud_rounded, AppColors.tosca),
  MoneyCategory('Other', Icons.add_rounded, AppColors.muted),
];

MoneyCategory categoryByName(String? name, {bool income = false}) {
  final list = income ? incomeSources : expenseCategories;
  for (final c in list) {
    if (c.name == name) return c;
  }
  for (final c in [...expenseCategories, ...incomeSources]) {
    if (c.name == name) return c;
  }
  return list.last;
}
