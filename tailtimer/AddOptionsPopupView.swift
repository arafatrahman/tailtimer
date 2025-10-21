import SwiftUI

struct AddOptionsPopupView: View {
    // Actions to perform when buttons are tapped
    var addPetAction: () -> Void
    var addMedicationAction: () -> Void
    var dismissAction: () -> Void // Action to close the popup

    var body: some View {
        VStack(spacing: 0) {
            Text("Add New")
                .font(.headline)
                .padding()

            Divider()

            Button {
                addPetAction()
            } label: {
                Label("Pet", systemImage: "pawprint")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()

            Divider()

            Button {
                addMedicationAction()
            } label: {
                Label("Medication", systemImage: "pills")
                     .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()

            Divider()

            Button("Cancel", role: .cancel) {
                dismissAction()
            }
            .padding()
        }
        .frame(width: 280)
        .background(Color(.systemBackground)) // Background of the popup card itself
        .cornerRadius(14)
        .shadow(radius: 10)
        // --- THIS IS THE FIX ---
        // Removed the .background modifier for the overlay
        // The ZStack in DashboardView handles the overlay background
        // --- END OF FIX ---
        // Allow tapping the outside area (handled by ZStack overlay in DashboardView)
        // .onTapGesture { dismissAction() } // This can also be removed if handled by the ZStack background tap
    }
}

// Preview (Optional, needs dummy actions)
struct AddOptionsPopupView_Previews: PreviewProvider {
    static var previews: some View {
        AddOptionsPopupView(
            addPetAction: { print("Add Pet") },
            addMedicationAction: { print("Add Med") },
            dismissAction: { print("Dismiss") }
        )
    }
}
