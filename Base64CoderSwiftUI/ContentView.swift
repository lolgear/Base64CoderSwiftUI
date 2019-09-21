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
        TextField("Encoded", text: $model)
    }
}
struct DecodedView : View {
    @Binding var model: String
    var body: some View {
        TextField("Decoded", text: $model)
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
    var body: some View {
        Form {
            EncodedView(model: self.$model.raw.string)
            DecodedView(model: self.$model.pretty.string)
            ErrorView(model: self.model.error)
        }
    }
}

struct TopMostView2 : View {
    var model = PublishersModel.example()
    @State var encoded: String = PublishersModel.example().raw.string
    @State var decoded: String = PublishersModel.example().pretty.string
    @State var error: Error?
    var body: some View {
        Form {
            EncodedView(model: Binding(get: {
                return self.encoded
            }, set: { (newValue) in
                self.encoded = newValue
                self.model.raw.string = newValue
            }) )
            DecodedView(model: Binding(get: {
                return self.decoded
            }, set: { (newValue) in
                self.decoded = newValue
                self.model.pretty.string = newValue
            }) )
            ErrorView(model: self.error)
        }.onReceive(self.model.willChange) { (value) in
            switch value {
            case let .success(raw, pretty):
                self.error = nil
                self.encoded = raw.string
                self.decoded = pretty.string
            case let .failure(error):
                self.error = error
            }
        }
    }
}

struct ContentView : View {
    var body: some View {
        TabView {
            TopMostView2().tabItem {
                Text("With publishers").font(Font.headline)
            }
            TopMostView().tabItem {
                Text("Without publishers").font(Font.headline)
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
