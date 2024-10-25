import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safe_circle/utils/quetos.dart';
import 'package:safe_circle/widgets/home_widgets/safeweb_view.dart';

class Customcarouel extends StatelessWidget {
  const Customcarouel({super.key});

  void navigateToRoute(BuildContext context, Widget route) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => route));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CarouselSlider(
          items: List.generate(
            imageSliders.length,
            (index) => Card(
              elevation: 5.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: () {
                  if (index == 0) {
                    navigateToRoute(
                      context,
                      SafeWebView(url: "https://www.rawatbedcollege.org/blog/womens-empowerment-in-india-and-its-importance")
                    );
                  }
                  if (index == 1) {
                    navigateToRoute(
                      context,
                      SafeWebView(
                          url:
                              "https://www.nextias.com/blog/women-empowerment/"),
                    );
                  }
                  if (index == 2) {
                    navigateToRoute(
                      context,
                      SafeWebView(
                          url:
                              "https://timesofindia.indiatimes.com/readersblog/scatteredthoughts/womens-empowerment-in-india-from-ancient-period-to-modern-time-period-46689/"),
                    );
                  }
                  if (index == 3) {
                    navigateToRoute(
                      context,
                      SafeWebView(
                          url:
                              "https://zhl.org.in/blog/growing-need-women-safety-india/"),
                    );
                  }
                  if (index == 4) {
                    navigateToRoute(
                      context,
                      SafeWebView(
                          url:
                              "https://www.iasgyan.in/blogs/female-iasips-officers-who-inspire-us"),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                        image: Image.asset(imageSliders[index]).image,
                        fit: BoxFit.cover),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        articleTitle[index],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.05),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          options: CarouselOptions(
              aspectRatio: 2.0, autoPlay: true, enlargeCenterPage: true)),
    );
  }
}
