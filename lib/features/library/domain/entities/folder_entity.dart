class FolderEntity {
  final String relativePath;
  final String name;
  final int documentCount;
  final int directDocumentCount;
  final bool isVirtualAll;

  const FolderEntity({
    required this.relativePath,
    required this.name,
    this.documentCount = 0,
    this.directDocumentCount = 0,
    this.isVirtualAll = false,
  });

  bool get isRoot => relativePath.isEmpty && !isVirtualAll;

  FolderEntity copyWith({
    String? relativePath,
    String? name,
    int? documentCount,
    int? directDocumentCount,
    bool? isVirtualAll,
  }) {
    return FolderEntity(
      relativePath: relativePath ?? this.relativePath,
      name: name ?? this.name,
      documentCount: documentCount ?? this.documentCount,
      directDocumentCount: directDocumentCount ?? this.directDocumentCount,
      isVirtualAll: isVirtualAll ?? this.isVirtualAll,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderEntity &&
          relativePath == other.relativePath &&
          isVirtualAll == other.isVirtualAll;

  @override
  int get hashCode => Object.hash(relativePath, isVirtualAll);
}