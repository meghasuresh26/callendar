import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(CalendarApp());
}

class CalendarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  final Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // Load events from SharedPreferences
  Future<void> _loadEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      Map<String, dynamic> eventsMap = jsonDecode(eventsJson);
      setState(() {
        _events.clear();
        eventsMap.forEach((key, value) {
          _events[DateTime.parse(key)] = List<String>.from(value);
        });
      });
    }
  }

  // Save events to SharedPreferences
  Future<void> _saveEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, List<String>> eventsMap = {};
    _events.forEach((key, value) {
      eventsMap[key.toIso8601String()] = value;
    });
    String eventsJson = jsonEncode(eventsMap);
    prefs.setString('events', eventsJson); // Save events as JSON string
  }

  // This is a simple event loader that you can expand for real use cases
  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _focusedDate = focusedDay;
    });
    _showEventDialog(selectedDay);
  }

  // Show the events for the selected day
  void _showEventDialog(DateTime selectedDay) {
    final events = _getEventsForDay(selectedDay);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Events for ${selectedDay.toLocal()}'),
        content: events.isNotEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: events
                    .asMap()
                    .entries
                    .map((entry) => ListTile(
                          title: Text(entry.value),
                          trailing: IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () {
                              _showEditDeleteDialog(
                                  selectedDay, entry.key, entry.value);
                            },
                          ),
                        ))
                    .toList(),
              )
            : const Text('No events for this day.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Show a dialog with options to Edit or Delete the event
  void _showEditDeleteDialog(DateTime selectedDay, int index, String event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Event'),
        content: Text('What would you like to do with this event?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditEventDialog(selectedDay, index, event);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(selectedDay, index);
            },
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Show the dialog to edit the selected event
  void _showEditEventDialog(DateTime selectedDay, int index, String event) {
    final _eventController = TextEditingController(text: event);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Event'),
        content: TextField(
          controller: _eventController,
          decoration: const InputDecoration(labelText: 'Event Name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_eventController.text.isNotEmpty && _selectedDate != null) {
                setState(() {
                  // Replace the old event with the edited one
                  _events[_selectedDate!]?[index] = _eventController.text;
                });
                _saveEvents(); // Save after editing
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Delete the selected event
  void _deleteEvent(DateTime selectedDay, int index) {
    setState(() {
      _events[selectedDay]?.removeAt(index);
      if (_events[selectedDay]?.isEmpty ?? false) {
        _events.remove(selectedDay);
      }
    });
    _saveEvents(); // Save after deleting
  }

  // Add a new event
  void _showAddEventDialog() {
    final _eventController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Event'),
        content: TextField(
          controller: _eventController,
          decoration: const InputDecoration(labelText: 'Event Name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_eventController.text.isNotEmpty && _selectedDate != null) {
                setState(() {
                  if (_events[_selectedDate!] == null) {
                    _events[_selectedDate!] = [];
                  }
                  _events[_selectedDate!]!.add(_eventController.text);
                });
                _saveEvents(); // Save after adding
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ScheduleHub',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Bold text
            color: Colors.red, // White text color
          ),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDate,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            calendarFormat: _calendarFormat,
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold, // Bold month and year
                fontSize: 20,
                color: Colors.blue, // Blue color for month and year
              ),
              formatButtonTextStyle: TextStyle(color: Colors.white),
              formatButtonDecoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            calendarStyle: CalendarStyle(
              todayTextStyle: TextStyle(color: Colors.green), // Color for today
              selectedTextStyle:
                  TextStyle(color: Colors.white), // Color for selected day
              selectedDecoration: BoxDecoration(
                color: Colors.blue, // Blue color for selected day
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(
                color: Colors.black, // Color for weekends (Saturday and Sunday)
              ),
              defaultTextStyle:
                  TextStyle(color: Colors.black), // Color for weekdays
              // Add red color for days with events
              outsideTextStyle:
                  TextStyle(color: Colors.grey), // For outside days
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedDate != null)
            ..._getEventsForDay(_selectedDate!).map((event) => ListTile(
                  title: Text(event),
                )),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              _showAddEventDialog();
            },
            child: const Text('Add Event'),
          ),
        ],
      ),
    );
  }
}
