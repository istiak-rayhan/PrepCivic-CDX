import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class DebugCheckScreen extends StatefulWidget {
  const DebugCheckScreen({super.key});

  @override
  State<DebugCheckScreen> createState() => _DebugCheckScreenState();
}

class _DebugCheckScreenState extends State<DebugCheckScreen> {
  Map<String, int> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDatabase();
  }

  Future<void> _checkDatabase() async {
    final db = await DatabaseHelper.instance.database;

    // Count questions per category
    final result = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM questions GROUP BY category',
    );

    Map<String, int> newStats = {};
    for (var row in result) {
      newStats[row['category'] as String] = row['count'] as int;
    }

    setState(() {
      stats = newStats;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Database Status Check")),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storage, size: 50, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text(
                    "📊 Data Loaded in SQLite:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (stats.isEmpty)
                    const Text(
                      "❌ Database is EMPTY!",
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    )
                  else
                    ...stats.entries
                        .map(
                          (e) => ListTile(
                            leading: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            title: Text(e.key),
                            trailing: Text(
                              "${e.value} Questions",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                        .toList(),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _checkDatabase,
                    child: const Text("Refresh Data"),
                  ),
                ],
              ),
      ),
    );
  }
}
