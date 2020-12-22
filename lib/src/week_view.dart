import 'package:event_calendar/src/day_container.dart';
import 'package:event_calendar/src/event_item.dart';
import 'package:event_calendar/src/models/event_model.dart';
import 'package:event_calendar/src/more_events.dart';
import 'package:event_calendar/src/utilities/calendar_utils.dart';
import 'package:flutter/material.dart';

final double dateTextHeight = 30;
final double eventItemHeight = 20;

class WeekView extends StatefulWidget {
  const WeekView({
    this.weekNumber,
    this.currentMonthDate,
    this.width,
    this.height,
  });

  final int weekNumber;
  final DateTime currentMonthDate;
  final double width;
  final double height;
  @override
  _WeekViewState createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  int daysBeforeStart;
  int noOfDaysTillPastWeek;
  List<EventModel> eventsInCurrentWeek;
  List<int> currentDayEventPositionsInStack = List();
  List<Widget> dayViewWidgets = [];
  List<Widget> stackWidgets = [];

  int get paddingBeforeStartDayOfMonth {
    DateTime dateTime = DateTime(widget.currentMonthDate.year, widget.currentMonthDate.month, 1);
    return dateTime.weekday == 7 ? 0 : dateTime.weekday;
  }

  int get numberOfDays => getNumberOfDaysInMonth(widget.currentMonthDate);

  List<EventModel> sortedAccordingToTheDuration(DateTime date) {
    List<EventModel> events = List();
    currentDayEventPositionsInStack = List(); //resetting current day positions in stack
    for (EventModel event in eventsInCurrentWeek) {
      DateTime startDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      DateTime endDate = DateTime(event.endTime.year, event.endTime.month, event.endTime.day);
      if (date.compareTo(startDate) >= 0 && date.compareTo(endDate) <= 0) {
        if (events.contains(event)) continue;
        events.add(event);
        currentDayEventPositionsInStack.add(event.positionInStack);
      }
    }
    events.sort(comparator);
    return events;
  }

  void setEventsInWeekWithStartDate(int date) {
    int totDays = numberOfDays;
    eventsInCurrentWeek = List();
    for (int i = 0; i < 7; i++, date++) {
      if (date <= 0 || date > totDays) continue;
      eventsInCurrentWeek
          .addAll(getEventsOn(DateTime(widget.currentMonthDate.year, widget.currentMonthDate.month, date)));
    }
  }

  void checkAndAddEventToStack(int numberOfEventsToDisplay, EventModel event, DateTime currentDay, int currentDayNumber,
      int i, List<Widget> stackWidgets, List<Widget> eventWidgetsInDay) {
    for (int position = 0; position < numberOfEventsToDisplay; position++) {
      if (currentDayEventPositionsInStack.contains(position) ||
          (position < eventWidgetsInDay.length && eventWidgetsInDay.elementAt(position) is EventItem)) {
        continue;
      }
      currentDayEventPositionsInStack.add(position);
      event.positionInStack = position;
      final int eventDuration = event.endTime.difference(currentDay).inDays + 1;
      final int noOfDaysLeftInWeek =
          (numberOfDays - currentDayNumber) + 1 >= (7 - i) ? 7 - i : (numberOfDays - currentDayNumber) + 1;
      final double width = (eventDuration <= noOfDaysLeftInWeek ? eventDuration : noOfDaysLeftInWeek) * widget.width;
      stackWidgets.add(
        Positioned(
          left: i * widget.width,
          top: position * (eventItemHeight + 20) + dateTextHeight,
          width: width,
          child: EventItem(event: event),
        ),
      );
      eventWidgetsInDay.add(SizedBox(height: eventItemHeight + 15));
      break; //break after the event is added
    }
  }

  @override
  void initState() {
    daysBeforeStart = paddingBeforeStartDayOfMonth;
    noOfDaysTillPastWeek = (widget.weekNumber) * 7 - daysBeforeStart;
    int currentDayNumber = noOfDaysTillPastWeek + 1;
    setEventsInWeekWithStartDate(currentDayNumber);

    for (int i = 0; i < 7; i++, currentDayNumber++) {
      final List<Widget> eventWidgetsInDay = [];
      if (currentDayNumber <= 0 || currentDayNumber > numberOfDays) {
        dayViewWidgets.add(Container(
          width: widget.width,
          padding: EdgeInsets.only(top: 5),
        ));
      } else {
        final int numberOfEventsToDisplay = (widget.height - dateTextHeight) ~/ eventItemHeight;
        final DateTime currentDay =
            DateTime(widget.currentMonthDate.year, widget.currentMonthDate.month, currentDayNumber);
        final List<EventModel> sorted = sortedAccordingToTheDuration(currentDay);

        if (numberOfEventsToDisplay != 0) {
          for (EventModel event in sorted) {
            final DateTime startDate = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
            final DateTime endDate = DateTime(event.endTime.year, event.endTime.month, event.endTime.day);
            if (eventWidgetsInDay.length == numberOfEventsToDisplay &&
                eventWidgetsInDay.length >= currentDayEventPositionsInStack.length) {
              break;
            }
            if (event.positionInStack >= 0) {
              eventWidgetsInDay.add(SizedBox(height: eventItemHeight + 15));
              continue;
            } else if ((startDate.difference(currentDay).inDays.abs() > 0 ||
                    endDate.difference(currentDay).inDays.abs() > 0) &&
                currentDay.compareTo(DateTime(currentDay.year, currentDay.month, numberOfDays)) != 0) {
              checkAndAddEventToStack(
                  numberOfEventsToDisplay, event, currentDay, currentDayNumber, i, stackWidgets, eventWidgetsInDay);
            } else {
              if (eventWidgetsInDay.length >= numberOfEventsToDisplay)
                continue;
              else {
                for (int position = 0; position < numberOfEventsToDisplay; position++) {
                  if (currentDayEventPositionsInStack.contains(position) ||
                      (position < eventWidgetsInDay.length && eventWidgetsInDay.elementAt(position) is EventItem)) {
                    //ignoring position if the position is already occupied in stack or if the position already has valid event item widget
                    continue;
                  }
                  eventWidgetsInDay.insert(
                    position,
                    EventItem(event: event),
                  );
                  break;
                }
              }
            }
          }
        }
        dayViewWidgets.add(DayContainer(
          day: currentDay,
          currentMonthDate: widget.currentMonthDate,
          eventWidgets: eventWidgetsInDay,
          width: widget.width,
        ));
        if (sorted.length - numberOfEventsToDisplay > 0) {
          const size = 25.0;
          stackWidgets.add(Positioned(
            left: i * widget.width,
            top: 0,
            width: size,
            child: MoreEvents(
              onTap: () => print('${sorted.length - numberOfEventsToDisplay} more event(s)'),
              value: sorted.length - numberOfEventsToDisplay,
              size: size,
            ),
          ));
        }
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: dayViewWidgets,
        ),
        ...stackWidgets,
      ],
    );
  }
}
