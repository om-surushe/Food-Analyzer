// class FoodResponse(BaseModel):
//     has_nuts: Optional[bool] = False
//     has_onion: Optional[bool] = False
//     has_garlic: Optional[bool] = False
//     has_lactose: Optional[bool] = False
//     has_allergen: Optional[bool] = False
//     has_peanut: Optional[bool] = False
//     has_sodium: Optional[bool] = False
//     sodium_quantity: Optional[float] = 0
//     sodiumu_percentage: Optional[float] = 0
//     has_sugar: Optional[bool] = False
//     sugar_quantity: Optional[float] = 0
//     sugar_percentage: Optional[float] = 0
//     has_carbs: Optional[bool] = False
//     carbs_quantity: Optional[float] = 0
//     carbs_percentage: Optional[float] = 0
//     good_ingrediants: list = []
//     bad_ingrediants: list = []

class FoodResponse{
  final bool has_nuts;
  final bool has_onion;
  final bool has_garlic;
  final bool has_lactose;
  final bool has_allergen;
  final bool has_peanut;
  final bool has_sodium;
  final num sodium_quantity;
  final num sodiumu_percentage;
  final bool has_sugar;
  final num sugar_quantity;
  final num sugar_percentage;
  final bool has_carbs;
  final num carbs_quantity;
  final num carbs_percentage;
  final List good_ingrediants;
  final List bad_ingrediants;

  FoodResponse({
    required this.has_nuts,
    required this.has_onion,
    required this.has_garlic,
    required this.has_lactose,
    required this.has_allergen,
    required this.has_peanut,
    required this.has_sodium,
    required this.sodium_quantity,
    required this.sodiumu_percentage,
    required this.has_sugar,
    required this.sugar_quantity,
    required this.sugar_percentage,
    required this.has_carbs,
    required this.carbs_quantity,
    required this.carbs_percentage,
    required this.good_ingrediants,
    required this.bad_ingrediants,
  });

  factory FoodResponse.fromJson(Map<String, dynamic> json) {
    return FoodResponse(
      has_nuts: json['has_nuts'],
      has_onion: json['has_onion'],
      has_garlic: json['has_garlic'],
      has_lactose: json['has_lactose'],
      has_allergen: json['has_allergen'],
      has_peanut: json['has_peanut'],
      has_sodium: json['has_sodium'],
      sodium_quantity: json['sodium_quantity'],
      sodiumu_percentage: json['sodiumu_percentage'],
      has_sugar: json['has_sugar'],
      sugar_quantity: json['sugar_quantity'],
      sugar_percentage: json['sugar_percentage'],
      has_carbs: json['has_carbs'],
      carbs_quantity: json['carbs_quantity'],
      carbs_percentage: json['carbs_percentage'],
      good_ingrediants: json['good_ingrediants'],
      bad_ingrediants: json['bad_ingrediants'],
    );
  }
}
