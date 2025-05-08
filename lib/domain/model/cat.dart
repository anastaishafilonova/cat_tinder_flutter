class CatModel {
  String imageUrl;
  String breed;
  String description;

  CatModel(this.imageUrl, this.breed, this.description);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatModel &&
          runtimeType == other.runtimeType &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => imageUrl.hashCode;
}
