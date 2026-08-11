struct FeedbackCategoryDisclosureState: Equatable {
    var isExpanded = false

    mutating func toggle() {
        isExpanded.toggle()
    }

    mutating func collapse() {
        isExpanded = false
    }
}
