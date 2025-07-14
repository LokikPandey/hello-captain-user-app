import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '../Resources/colors.dart';
import '../Resources/commons.dart';

class KCarousel extends StatefulWidget {
  final List<dynamic> images;
  final List<Widget> children;
  final double height;
  final bool isLooped;
  final double indicatorSpace;
  final bool showIndicator;

  const KCarousel({
    super.key,
    this.children = const [],
    this.height = 200,
    required this.isLooped,
    this.indicatorSpace = 0,
    this.images = const [],
    this.showIndicator = true,
  });

  static Widget item({
    void Function()? onTap,
    EdgeInsetsGeometry? padding,
    required String url,
    double? radius,
    bool showShadow = true,
    bool isCached = false,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 15.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: showShadow
                ? [
                    const BoxShadow(
                      color: Kolor.border,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
            borderRadius: kRadius(radius ?? 15),
            image: DecorationImage(
              image: isCached
                  ? CachedNetworkImageProvider(url)
                  : NetworkImage(url),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<KCarousel> createState() => _KCarouselState();
}

class _KCarouselState extends State<KCarousel> {
  int activePage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: widget.indicatorSpace,
      children: [
        FlutterCarousel(
          options: FlutterCarouselOptions(
            height: widget.height,
            viewportFraction: 1,
            pageSnapping: true,
            showIndicator: false,
            floatingIndicator: true,
            enableInfiniteScroll: true,
            padEnds: false,
            autoPlay: widget.isLooped,
            onPageChanged: (index, reason) {
              setState(() {
                activePage = index;
              });
            },
          ),
          items: widget.images.isNotEmpty
              ? widget.images
                  .map((url) => KCarousel.item(
                        isCached: true,
                        onTap: () async {
                          // Handle tap action
                        },
                        showShadow: false,
                        radius: 10,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        url: url,
                      ))
                  .toList()
              : widget.children,
        ),
        if ((widget.showIndicator &&
                widget.images.length > 1 &&
                widget.children.isEmpty) ||
            widget.children.isNotEmpty)
          Visibility(
            visible: widget.showIndicator && widget.children.length > 1,
            child: _indicator(
              activeIndex: activePage,
              length: widget.images.isNotEmpty
                  ? widget.images.length
                  : widget.children.length,
            ),
          ),
      ],
    );
  }

  Widget _indicator({required int activeIndex, required int length}) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, top: 10),
      child: SafeArea(
        child: Row(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            length,
            (index) => AnimatedContainer(
              curve: Curves.ease,
              duration: const Duration(milliseconds: 300),
              height: 5,
              width: activeIndex == index ? 15 : 4,
              decoration: BoxDecoration(
                borderRadius: kRadius(100),
                color: activeIndex == index ? Kolor.secondary : Kolor.border,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
