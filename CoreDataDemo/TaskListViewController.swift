//
//  TaskListViewController.swift
//  CoreDataDemo
//
//  Created by Alexey Efimov on 06.12.2021.
//

import UIKit
import CoreData

class TaskListViewController: UITableViewController {
    
    var context: NSManagedObjectContext!
    var taskList: [Task] = []
    let cellID = "task"
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        view.backgroundColor = .white
        setupNavigationBar()
        
        context = StorageManager.shared.persistentContainer.viewContext
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
        tableView.reloadData()
    }
    
    private func setupNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navBarAppearance.backgroundColor = UIColor(
            red: 21/255,
            green: 101/255,
            blue: 192/255,
            alpha: 194/255
        )
        
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        navigationItem.leftBarButtonItem = self.editButtonItem
        navigationController?.navigationBar.tintColor = .white
    }
    
    @objc private func addNewTask() {
        showAlert(with: "New task", and: "What do you want to do?")
    }
    
    private func fetchData() {
        let fetchRequest = Task.fetchRequest()
        
        do {
            taskList = try context.fetch(fetchRequest)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func showAlert(with title: String, and message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let task = alert.textFields?.first?.text, !task.isEmpty else { return }
            self.save(task)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            textField.placeholder = "New Task"
        }
        present(alert, animated: true)
    }
    
    private func showChangeAlert(at row: Int) {
        let alert = UIAlertController(title: "Update Task",
                                      message: "What do you want to change",
                                      preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .destructive) { _ in
            guard let task = alert.textFields?.first?.text, !task.isEmpty else { return }
            self.update(at: row, newTitle: task)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField()
        alert.textFields?.first?.text = taskList[row].title
        
        present(alert, animated: true)
    }
    
    private func update(at index: Int, newTitle: String) {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        do {
            let taskList = try context.fetch(fetchRequest)
            let taskToUpdate = taskList[index] as NSManagedObject
            taskToUpdate.setValue(newTitle, forKey: "title")
            self.taskList[index].title = newTitle
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            
            do {
                try context.save()
            } catch let error {
                print(error.localizedDescription)
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private func delete(at index: Int) {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        do {
            let taskList = try context.fetch(fetchRequest)
            let taskToDelete = taskList[index] as NSManagedObject
            context.delete(taskToDelete)
            self.taskList.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            
            do {
                try context.save()
            } catch let error {
                print(error.localizedDescription)
            }
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    private func save(_ taskName: String) {
        let task = Task(context: context)
        task.date = Date()
        task.title = taskName
        taskList.append(task)
        
        let cellIndex = IndexPath(row: taskList.count - 1, section: 0)
        tableView.insertRows(at: [cellIndex], with: .automatic)
        
        if context.hasChanges {
            do {
                try context.save()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    private func doneAction(at indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .destructive, title: "Done") { action, view, completion in
            completion(true)
        }
        showChangeAlert(at: indexPath.row)
        action.backgroundColor = .systemBlue
        action.image = UIImage(systemName: "checkmark.circle")
        return action
    }
    
}

extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let task = taskList[indexPath.row]
        guard let taskDate = task.date else { return cell }
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        content.secondaryText = dateFormatter.string(from: taskDate)
        cell.contentConfiguration = content
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            delete(at: indexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let done = doneAction(at: indexPath)
        
        return UISwipeActionsConfiguration(actions: [done])
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return . delete
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let moveTask = taskList.remove(at: sourceIndexPath.row)
        taskList.insert(moveTask, at: destinationIndexPath.row)
        tableView.reloadData()
        if context.hasChanges {
            do {
                try context.save()
            } catch let error {
                printContent(error.localizedDescription)
            }
        }
    }
}
