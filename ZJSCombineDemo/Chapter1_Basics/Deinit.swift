
class A {
    
    init() {
        
    }
    
    deinit {
        
    }
}

class B : A {
        
//     deinit {
//        
//     }
}

class C : B {

    
    @MainActor
    deinit {
        
    }
}
