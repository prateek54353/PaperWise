import 'dart:io';
import 'command.dart';

/// Command to add an image to the list
class AddImageCommand implements Command {
  final List<File> images;
  final File image;
  final int index;

  AddImageCommand({
    required this.images,
    required this.image,
    this.index = -1, // -1 means add to end
  });

  @override
  void execute() {
    if (index == -1) {
      images.add(image);
    } else {
      images.insert(index, image);
    }
  }

  @override
  void undo() {
    if (index == -1) {
      images.remove(image);
    } else {
      images.removeAt(index);
    }
  }

  @override
  String get description => 'Add image';
}

/// Command to remove an image from the list
class RemoveImageCommand implements Command {
  final List<File> images;
  final File image;
  late int _index;

  RemoveImageCommand({
    required this.images,
    required this.image,
  }) {
    _index = images.indexOf(image);
  }

  @override
  void execute() {
    _index = images.indexOf(image);
    images.remove(image);
  }

  @override
  void undo() {
    if (_index >= 0) {
      images.insert(_index, image);
    } else {
      images.add(image);
    }
  }

  @override
  String get description => 'Remove image';
}

/// Command to reorder images
class ReorderImagesCommand implements Command {
  final List<File> images;
  final int oldIndex;
  final int newIndex;

  ReorderImagesCommand({
    required this.images,
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  void execute() {
    int adjustedNewIndex = newIndex;
    if (oldIndex < adjustedNewIndex) {
      adjustedNewIndex -= 1;
    }
    final item = images.removeAt(oldIndex);
    images.insert(adjustedNewIndex, item);
  }

  @override
  void undo() {
    // Reverse the operation
    int adjustedOldIndex = oldIndex;
    if (newIndex < adjustedOldIndex) {
      adjustedOldIndex -= 1;
    }
    final item = images.removeAt(newIndex);
    images.insert(adjustedOldIndex, item);
  }

  @override
  String get description => 'Reorder images';
}

/// Command to replace an image (after crop or filter)
class ReplaceImageCommand implements Command {
  final List<File> images;
  final File oldImage;
  final File newImage;
  late int _index;

  ReplaceImageCommand({
    required this.images,
    required this.oldImage,
    required this.newImage,
  }) {
    _index = images.indexOf(oldImage);
  }

  @override
  void execute() {
    _index = images.indexOf(oldImage);
    if (_index >= 0) {
      images[_index] = newImage;
    }
  }

  @override
  void undo() {
    if (_index >= 0) {
      images[_index] = oldImage;
    }
  }

  @override
  String get description => 'Edit image';
}
