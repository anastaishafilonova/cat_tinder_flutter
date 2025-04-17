class Cat {
  String imageUrl;
  String breed;
  String description;

  Cat(this.imageUrl, this.breed, this.description);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cat &&
          runtimeType == other.runtimeType &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => imageUrl.hashCode;
}
