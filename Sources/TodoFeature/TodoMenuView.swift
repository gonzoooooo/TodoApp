import CoreDataModels
import SwiftUI

@available(iOS 15, *)
public struct TodoMenuView: View {
    @ObservedObject
    private var viewModel: TodoMenuViewModel

    public init(viewModel: TodoMenuViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            NavigationLink() {
                TodoListView(viewModel: viewModel.todoListViewModel(buttonType: .all))
            } label: {
                HStack {
                    Image(systemName: "tray.full.fill")
                        .foregroundColor(.systemGray)
                        .font(.title2)
                        .frame(width: 44)

                    Text("All")
                }
            }

            NavigationLink() {
                TodoListView(viewModel: viewModel.todoListViewModel(buttonType: .flagged))
            } label: {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                        .frame(width: 44)

                    Text("Flagged")
                }
            }
        }
        .navigationTitle("Todo")
    }
}

#if DEBUG

import DatabaseClients
import NotificationClient

struct TodoMenuView_Previews: PreviewProvider {
   static var previews: some View {
       let todoClient = TodoClient.preview
       let notificationClient = NotificationClient.shared
       let viewModel = TodoMenuViewModel(todoClient: todoClient, notificationClient: notificationClient)

       Group {
           NavigationView {
               TodoMenuView(viewModel: viewModel)
           }
           .previewDevice(PreviewDevice(rawValue: "iPhone 12 Mini"))
           .previewDisplayName("iPhone 12 Mini")

           NavigationView {
               TodoMenuView(viewModel: viewModel)
                   .preferredColorScheme(.dark)
           }
           .environment(\.locale, Locale(identifier: "ja-JP"))
           .previewDevice(PreviewDevice(rawValue: "iPhone 12 Mini"))
           .previewDisplayName("iPhone 12 Mini")

           NavigationView {
               TodoMenuView(viewModel: viewModel)
           }
           .previewDevice(PreviewDevice(rawValue: "iPhone 12 Pro Max"))
           .previewDisplayName("iPhone 12 Pro Max")
       }
   }
}

#endif
