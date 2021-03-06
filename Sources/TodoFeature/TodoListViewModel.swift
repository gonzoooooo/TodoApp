import CoreDataModels
import CommonViews
import DatabaseClients
import Foundation
import SwiftUI
import NotificationClient

public final class TodoListViewModel: NSObject, ObservableObject {
    @Published
    private(set) var todos: [Todo] = []

    @Published
    var isHiddenCompletedTodos = false

    @Published
    private(set) var isHiddenUnflaggedTodos = false

    @Published
    var searchText = ""

    @Published
    var editMode: EditMode = .inactive

    @Published
    var selectMode: SelectMode = .inactive

    @Published
    var selection: Set<UUID> = []

    @Published
    var presentingNewTodoView = false

    @Published
    var presentedTodo: Todo?

    @Published
    var presentedConfirmationForRemoveTasks = false

    private(set) var defaultNavigationTitle: String

    private let todoClient: TodoClient
    private let notificationClient: NotificationClient

    var navigationTitle: Text {
        selection.isEmpty ? Text(defaultNavigationTitle) : Text("\(selection.count) Selected")
    }

    var newTodoViewModel: NewTodoViewModel {
        .init(todoClient: todoClient, notificationClient: notificationClient)
    }

    public init(
        todoClient: TodoClient,
        notificationClient: NotificationClient,
        isHiddenUnflaggedTodos: Bool = false,
        defaultNavigationTitle: String = String(localized: "Tasks")
    ) {
        self.todoClient = todoClient
        self.notificationClient = notificationClient
        self.isHiddenUnflaggedTodos = isHiddenUnflaggedTodos
        self.defaultNavigationTitle = defaultNavigationTitle
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextObjectsDidChange(_:)),
            name: Notification.Name.NSManagedObjectContextObjectsDidChange,
            object: nil
        )

        fetch()
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name.NSManagedObjectContextObjectsDidChange,
            object: nil
        )
    }

    func fetch() {
        todos = todoClient.fetch(
            predicate: searchPredicate,
            sortDescriptors: [NSSortDescriptor(keyPath: \Todo.order, ascending: true)]
        )
    }

    public func add(
        name: String,
        notifiedDate: Date?,
        isFlagged: Bool
    ) async throws {
        try? await todoClient.add(
            id: UUID(),
            name: name,
            notifiedDate: notifiedDate,
            isFlagged: isFlagged
        )
    }

    func moveTodos(from source: IndexSet, to destination: Int) {
        var objectIDs = todos.map { $0.objectID }
        objectIDs.move(fromOffsets: source, toOffset: destination)

        do {
            try todoClient.updateOrder(objectIDs: objectIDs)
        } catch {
            print("error: \(error)")
        }
    }

    func deleteTodos(offsets: IndexSet) async {
        await todoClient.delete(identifiedBy: offsets.map { todos[$0].objectID })
    }

    func deleteTodos(ids: Set<UUID>) async {
        await todoClient.delete(ids: ids)
    }

    func todoListRowViewModel(todo: Todo) -> TodoListRowViewModel {
        TodoListRowViewModel(
            todo: todo,
            todoClient: todoClient,
            editMode: editMode
        )
    }

    func todoDetailViewModel(todo: Todo) -> TodoDetailViewModel {
        TodoDetailViewModel(
            todo: todo,
            todoClient: todoClient,
            notificationClient: notificationClient
        )
    }

    @objc
    func contextObjectsDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            // needed?
            try? self.todoClient.saveIfNeeded()
            self.fetch()
        }
    }

    private var searchPredicate: NSPredicate {
        var predicates = [NSPredicate]()

        if isHiddenUnflaggedTodos {
            predicates.append(NSPredicate(format: "%K == true", #keyPath(Todo.isFlagged)))
        }

        if isHiddenCompletedTodos {
            predicates.append(NSPredicate(format: "%K == false", #keyPath(Todo.isCompleted)))
        }

        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "%K BEGINSWITH[cd] %@", #keyPath(Todo.name), searchText))
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
