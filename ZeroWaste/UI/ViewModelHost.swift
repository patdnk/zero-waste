//
//  ViewModelHost.swift
//  ZeroWaste
//
//  Keeps a factory-built view model alive across parent re-renders. Factories are called
//  from view builders (tabs, sheets, navigation destinations) which SwiftUI re-evaluates
//  freely; without this the view model would be recreated and lose its state.
//

import SwiftUI

struct ViewModelHost<Model: AnyObject, Content: View>: View {
    @State private var model: Model
    private let content: (Model) -> Content

    init(_ model: Model, @ViewBuilder content: @escaping (Model) -> Content) {
        _model = State(initialValue: model)
        self.content = content
    }

    var body: some View {
        content(model)
    }
}
