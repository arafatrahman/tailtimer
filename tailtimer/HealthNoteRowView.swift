import SwiftUI

struct HealthNoteRowView: View {
    let note: HealthNote
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                Text(note.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if note.photo != nil {
                Image(systemName: "photo.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
