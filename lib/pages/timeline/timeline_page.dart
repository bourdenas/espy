import 'package:espy/pages/timeline/annual_review.dart';
import 'package:flutter/material.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key, required this.year});

  final String year;

  @override
  TimelinePageState createState() => TimelinePageState();
}

class TimelinePageState extends State<TimelinePage> {
  late String selectedYear;

  @override
  void initState() {
    super.initState();

    selectedYear = widget.year;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            yearBar(context),
            const SizedBox(width: 4),
            Expanded(
              child: AnnualReview(year: selectedYear),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox yearBar(BuildContext context) {
    return SizedBox(
      width: 64,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final year in List.generate(47, (i) => '${2025 - i}'))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: selectedYear == year
                    ? IconButton.filled(
                        icon: Text(year),
                        onPressed: () {},
                      )
                    : IconButton.outlined(
                        icon: Text(year),
                        onPressed: () => setState(() {
                          selectedYear = year;
                        }),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
