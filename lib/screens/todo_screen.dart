import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late Isar _isar;
  List<Task> _tasks = [];
  bool _isDbReady = false;
  
  // The active filter state
  String _currentFilter = 'ALL';
  final List<String> _filters = ['ALL', 'PENDING', 'COMPLETED'];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  // --- DATABASE LOGIC ---
  Future<void> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.instanceNames.isEmpty) {
      _isar = await Isar.open([TaskSchema], directory: dir.path);
    } else {
      _isar = Isar.getInstance()!;
    }
    await _loadTasks();
    setState(() => _isDbReady = true);
  }

  Future<void> _loadTasks() async {
    List<Task> tasks;
    
    // Filter logic querying the database directly
    if (_currentFilter == 'PENDING') {
      tasks = await _isar.tasks.filter().isCompletedEqualTo(false).findAll();
    } else if (_currentFilter == 'COMPLETED') {
      tasks = await _isar.tasks.filter().isCompletedEqualTo(true).findAll();
    } else {
      tasks = await _isar.tasks.where().findAll();
    }

    setState(() {
      _tasks = tasks.reversed.toList(); // Show newest first
    });
  }

  Future<void> _saveOrEditTask(Task? existingTask) async {
    if (_titleController.text.trim().isEmpty) return;

    final task = existingTask ?? Task();
    task.title = _titleController.text.trim();
    task.description = _descController.text.trim().isNotEmpty ? _descController.text.trim() : null;
    
    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });

    _titleController.clear();
    _descController.clear();
    if (mounted) Navigator.pop(context);
    _loadTasks();
  }

  Future<void> _toggleTaskStatus(Task task) async {
    task.isCompleted = !task.isCompleted;
    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });
    _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.delete(task.id);
    });
    _loadTasks();
  }

  // --- UI LOGIC ---
  void _showTaskDialog({Task? task}) {
    if (task != null) {
      _titleController.text = task.title;
      _descController.text = task.description ?? '';
    } else {
      _titleController.clear();
      _descController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A), // Match the dark card theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task == null ? 'New Task' : 'Edit Task',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                autofocus: true,
                style: const TextStyle(fontSize: 18, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
              const Divider(color: Color(0xFF2A2A2A)),
              TextField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Add some details... (optional)',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD36B28),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _saveOrEditTask(task),
                  child: Text(
                    task == null ? 'Save Task' : 'Update Task',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits deep black from MainShell
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. The Header & Dynamic Badge
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
            child: Row(
              children: [
                const Text('Tasks', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Text(
                    '${_tasks.length}',
                    style: const TextStyle(color: Color(0xFFD36B28), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // 2. The Filter Pills
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: _filters.map((filter) {
                final isSelected = _currentFilter == filter;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentFilter = filter);
                    _loadTasks(); // Reloads DB based on new filter
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4A2A18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFD36B28) : const Color(0xFF2A2A2A),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFFD36B28) : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),

          // 3. The Main Content (Empty State or List)
          Expanded(
            child: !_isDbReady 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD36B28)))
                : _tasks.isEmpty 
                    ? _buildEmptyState() 
                    : _buildTaskList(),
          ),
        ],
      ),
      
      // 4. The FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        backgroundColor: const Color(0xFFD36B28),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: const Icon(Icons.insert_drive_file_outlined, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'No tasks yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create your first task.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 60), // Nudges it up slightly for the FAB
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 100),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final isDone = task.isCompleted;
        
        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            decoration: BoxDecoration(
              color: Colors.red.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => _deleteTask(task),
          child: GestureDetector(
            onTap: () => _showTaskDialog(task: task),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A), // Card background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _toggleTaskStatus(task),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24, height: 24,
                      margin: const EdgeInsets.only(top: 2, right: 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone ? const Color(0xFFD36B28) : Colors.grey.shade600,
                          width: 2,
                        ),
                        color: isDone ? const Color(0xFFD36B28) : Colors.transparent,
                      ),
                      child: isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
                            color: isDone ? Colors.grey : Colors.white,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (task.description != null && task.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            task.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}