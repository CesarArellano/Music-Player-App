import 'package:flutter/material.dart';
import 'package:focus_music_player/widgets/widgets.dart';
import 'package:shimmer/shimmer.dart';

class CustomLoader extends StatelessWidget {
  const CustomLoader({
    super.key,
    this.isGridView = false
  });

  final bool isGridView;

  @override
  Widget build(BuildContext context) {
    Widget widgetToShow = ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 15,
      itemBuilder:(context, index) {
        return const Column(
          children: [
            ContentPlaceholder(),
            SizedBox(height: 16.0),
          ],
        );
      },
    );

    if( isGridView ) {
      widgetToShow = GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 240,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4
        ),
        padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 15,
        itemBuilder:(context, index) => const ArtworkPlaceholder()
      );
    }

    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white38,
      enabled: true,
      child: widgetToShow
    );
  }
}