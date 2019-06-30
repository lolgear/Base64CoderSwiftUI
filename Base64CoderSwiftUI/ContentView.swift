//
//  ContentView.swift
//  Base64CoderSwiftUI
//
//  Created by Dmitry Lobanov on 30/06/2019.
//  Copyright © 2019 Dmitry Lobanov. All rights reserved.
//

import SwiftUI
import Combine

struct EncodedView : View {
    @Binding var model: String
    var body: some View {
        TextField($model, placeholder: Text("Encoded"), onEditingChanged: { (finished) in
            
        }) {
            
        }
    }
}
struct DecodedView : View {
    @Binding var model: String
    var body: some View {
        TextField($model, placeholder: Text("Decoded"), onEditingChanged: { (finished) in
            
        }) {
            
        }
    }
}

struct ErrorView : View {
    var model: Error?
    func exists() -> Bool {
        return self.model != nil
    }
    func errorDescription() -> String {
        return self.model?.localizedDescription ?? "No Error"
    }
    var body: some View {        Text(self.errorDescription()).multilineTextAlignment(.center).lineLimit(nil).foregroundColor(self.exists() ? .red : .green)
    }
}


struct TopMostView : View {
    @State var model = Model.example()
    @State var encoded = ""
    var body: some View {
        List {
            EncodedView(model: self.$model.raw.string)
            DecodedView(model: self.$model.pretty.string)
            ErrorView(model: self.model.error)
        }
    }
}

struct ContentView : View {

    var body: some View {
        TopMostView()
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
