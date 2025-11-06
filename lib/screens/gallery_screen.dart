import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/master.dart';
import 'master_detail_screen.dart';
import '../widgets/search_widget.dart';

class GalleryScreen extends StatelessWidget {
  late final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) => Image.network(imageUrls[index]),
    );
  }
}