import 'package:flutter/material.dart';

class CustomLoader extends StatelessWidget {
  const CustomLoader({
    super.key,
    this.isCreatingArtworks = false,
  });

  final bool isCreatingArtworks;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if( isCreatingArtworks ) ...[
            const SizedBox(height: 10),
            const Text('Creating new artworks...')
          ]
        ],
      )
    );
  }
}