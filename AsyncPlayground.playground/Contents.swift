//: Playground - noun: a place where people can play

import Foundation

enum ErrorType: Error {
    case zero
}


enum Result <T> {
    case Success(T)
    case Failure(ErrorType)
}

struct Async<T> {
    
    let trunk:(@escaping(Result<T>)->Void)->Void
    
    init(function: @escaping (@escaping(Result<T>)->Void)-> Void ){
        print("init")
        trunk = function
    }
    
    func execute(callBack: @escaping (Result<T>)->Void) {
        print("execute")
        trunk(callBack)    
    }
}

extension Result {
    
    static func unit<U>(x:U) -> Result<U> {
        return .Success(x)
    }
    
    func map<U>(f: @escaping(T) throws-> U ) -> Result<U> {
        return flatmap(f: { (t) -> Result<U> in
            return Result.unit(x: try f(t))
        })
    }
    
    func flatmap<U>(f: @escaping(T) throws-> Result<U>) -> Result<U> {
        switch self {
        case .Success(let value):
            do {
                return try f(value)
            } catch let e {
                return .Failure(e as! ErrorType)
            }
        case .Failure(let e):
            return .Failure(e)
        }
    }
}


extension Async {
    
    static func unit<U>(x:U) -> Async<U> {
        return Async<U>(function: { (function)  in
            function(.Success(x))
        })
    }
    
    func map<U>(f: @escaping (T) throws-> U) -> Async<U> {
        return flatmap(f: { (t) -> Async<U> in
            return  Async.unit(x: try f(t))
        })
    }
    
    func flatmap<U>(f: @escaping (T) throws-> Async<U>) -> Async<U> {
        
        return Async<U> {
            (function) -> Void in
            self.execute(callBack: { (result) in
                switch result.map(f: f){      // A-
                case .Success(let async):
                    async.execute(callBack: function)
                case .Failure(let error):
                    function(.Failure(error))
                }
            })
        }
    }
    
}


// Async Api 1
func loginWithUser(_ name: String) -> Async<String> {
    return Async(function: { (callback) in
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2, execute: {
            callback(Result.Success("Token:xxx"))
        })
    })
}
// Async Api 2
func downloadUserInfo(token: String) -> Async<[String: Any]> {
    return Async(function: { (callback) in
        DispatchQueue.global().asyncAfter(deadline: .now() + 2, execute: {
            callback(Result.Success(["Gender" : "M", "Height": 180]))
        })
    })
}

//Test method
func testLoginProcess() -> Void {
    
    let loginProcress = loginWithUser("John")
        .map { (token) -> String in
            print(token)
            return token
        }.flatmap { (token) -> Async<[String: Any]> in
            print(token)
            return downloadUserInfo(token: token)
        }.map { (info) -> Void in
            print(info)
        }
    
    print("loginProcress:  \(loginProcress)")
}

//Start test
testLoginProcess()
