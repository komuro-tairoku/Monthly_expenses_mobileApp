/// Maps stored category keys to translation keys
class CategoryTranslator {
  static const Map<String, String> _categoryToTranslationKey = {
    // Expense categories
    'Shopping': 'sheet.shopping',
    'Food': 'sheet.food',
    'Phone': 'sheet.phone',
    'Entertainment': 'sheet.entertainment',
    'Education': 'sheet.education',
    'Beauty': 'sheet.beauty',
    'Sports': 'sheet.sports',
    'Social': 'sheet.social',
    'Housing': 'sheet.housing',
    'Electricity Bill': 'sheet.electricity',
    'Water Bill': 'sheet.water',
    'Clothes': 'sheet.clothes',
    'Travel': 'sheet.transport',
    'Other Expenses': 'sheet.other_expense',

    // Income categories
    'Salary': 'sheet.salary',
    'Allowance': 'sheet.allowance',
    'Bonus': 'sheet.bonus',
    'Other Income': 'sheet.other_income',

    // Vietnamese versions (for backward compatibility)
    'Mua sắm': 'sheet.shopping',
    'Ăn uống': 'sheet.food',
    'Điện thoại': 'sheet.phone',
    'Giải trí': 'sheet.entertainment',
    'Giáo dục': 'sheet.education',
    'Làm đẹp': 'sheet.beauty',
    'Thể thao': 'sheet.sports',
    'Xã hội': 'sheet.social',
    'Nhà ở': 'sheet.housing',
    'Tiền điện': 'sheet.electricity',
    'Tiền nước': 'sheet.water',
    'Quần áo': 'sheet.clothes',
    'Đi lại': 'sheet.transport',
    'Chi khác': 'sheet.other_expense',
    'Lương': 'sheet.salary',
    'Phụ cấp': 'sheet.allowance',
    'Thưởng': 'sheet.bonus',
    'Thu khác': 'sheet.other_income',
  };

  /// Get translation key for a stored category
  /// Returns the translation key if found, otherwise returns the original category
  static String getTranslationKey(String storedCategory) {
    return _categoryToTranslationKey[storedCategory] ?? storedCategory;
  }

  /// Check if a category can be translated
  static bool isTranslatable(String category) {
    return _categoryToTranslationKey.containsKey(category);
  }
}
