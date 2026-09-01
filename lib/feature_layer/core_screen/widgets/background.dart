import 'package:flutter/material.dart';
import 'package:qb/shared/constants.dart';

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({super.key, required this.child, this.imageAsset});

  final Widget child;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          color: imageAsset == null
              ? (isDark ? const Color(0xFF16151A) : cLightBrown)
              : null,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: imageAsset != null
              ? BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage('$imageAsset'),
                  ),
                )
              : null,
        ),
        Align(alignment: Alignment.topCenter, child: child),
      ],
    );
  }
}
