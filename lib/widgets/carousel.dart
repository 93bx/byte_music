import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Carousel extends StatefulWidget {
  final double height;
  final List<Widget> items;
  final double viewport;
  final bool? showIndicator;

  const Carousel({
    super.key,
    required this.height,
    required this.items,
    required this.viewport,
    this.showIndicator = false,
  });

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  int _indicatorIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: widget.height,
            viewportFraction: widget.viewport,
            enableInfiniteScroll: false,
            padEnds: false,
            scrollDirection: Axis.horizontal,
            scrollPhysics: ClampingScrollPhysics(),
            onPageChanged: (index, reason) => setState(() => _indicatorIndex = index),
          ),
          items: widget.items,
        ),

        Visibility(
          visible: widget.showIndicator!,
          child: AnimatedSmoothIndicator(
            activeIndex: _indicatorIndex,
            count: widget.items.length,
            effect: WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: Colors.white,
              dotColor: Colors.white24,
              spacing: 5,
            ),
          ),
        )
      ],
    );
  }
}
