//
//  SwiftBasic.swift
//  demo
//
//  Created by RichardX on 2026/8/13.
//

import Foundation

/**
 项目AI管理结构
 YourProject/
 ├── .contextignore           # AI 忽略文件
 ├── AGENTS.md                # 项目级核心说明书
 ├── .agents/                 # AI 资产目录
 │   ├── skills/              # 技能包
 │   │   ├── swiftui-ui/      # SwiftUI UI 开发技能
 │   │   ├── flutter-widget/  # Flutter Widget 开发技能
 │   │   ├── api-client/      # 网络请求封装技能
 │   │   └── testing/         # 单元测试/UI 测试技能
 │   ├── templates/           # 提示模板
 │   │   ├── feature_request.md
 │   │   └── bug_fix.md
 │   └── agents/              # 智能体配置（可选）
 │       └── code-review.md
 └── README.md                # 项目说明
 
 项目结构定义
 SuperDemo/
 ├── iOS/ # SwiftUI 原生代码
 │ ├── App/ # App 入口及生命周期
 │ ├── Features/ # 各功能模块
 │ │ ├── Login/
 │ │ ├── Home/
 │ │ └── Profile/
 │ ├── Services/ # 网络、数据库等公共服务
 │ ├── Utils/ # 工具类/扩展
 │ └── Resources/ # 资源文件
 ├── flutter_module/ # Flutter 模块 (作为子模块或 Package)
 │ ├── lib/
 │ │ ├── features/
 │ │ ├── services/
 │ │ └── utils/
 │ └── pubspec.yaml
 └── shared/ # 跨平台共享资源（如 Proto 定义）
 */

//>>>>>>>>----------
//    // 字符串操作
//    let name = "Swift"
//    let greeting = "Hello, \(name)!" // Hello, Swift!
//    let multiline = """
//    这是多行字符串
//    保留缩进
//    """
//    init(numbers: [Int] = [1, 2, 3, 4, 5]) {
//        self.numbers = numbers
//    }
    
//    // 集合操作
//    nonisolated(unsafe) var numbers = [1, 2, 3, 4, 5]
//    let doubled = numbers.map { $0 * 2 } // [2,4,6,8,10]
//    let evens = numbers.filter { $0 % 2 == 0 } // [2,4]
//    let sum = numbers.reduce(0, +) // 15
    
//    // switch 模式匹配
//    let point = (2, 0)
//    switch point {
//        case (0, 0): print("原点")
//        case (_, 0): print("在 x 轴上")
//        case (0, _): print("在 y 轴上")
//        case let (x, y) where x == y: print("在对角线上")
//        default: print("普通点")
//    }
    
//    // 函数
//    func greet(_ person: String, from hometown: String = "北京") -> String {
//        return "你好，\(person)！来自\(hometown)"
//    }
    
//    print(greet("小明", from: "上海"))
//----------<<<<<<<<<<<


//>>>>>>>>----------
//struct User {
//    var name: String
//    var address: Address?
//}

//struct Address {
//    var city: String
//    var street: String
//}

//let user: User? = User(name: "Tom", address: Address(city: "北京", street: "中关村"))

//// 可选链：安全访问深层属性
//let city = user?.address?.city // String?
//if let city = city {
//    print("城市：\(city)")
//}

//// guard let 提前返回
//func printCity(of user: User?) {
//    guard let user = user, let address = user.address else {
//        print("信息不完整")
//        return
//    }
//    print("城市：\(address.city)")
//}

//// 空合并
//let name = user?.name ?? "未知用户"

//// 可选 map
//let nameLength = user.map { $0.name.count } // Int?
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
//struct Point {
//    var x: Double
//    var y: Double
//    
//    mutating func moveBy(x dx: Double, y dy: Double) {
//        x += dx
//        y += dy
//    }
//}

//class Shape {
//    var origin: Point
//    var name: String
//    
//    init(origin: Point, name: String) {
//        self.origin = origin
//        self.name = name
//    }
//}

//var p1 = Point(x: 0, y: 0)
//let p2 = p1 // 值拷贝
//p1.moveBy(x: 10, y: 10)
//print(p1.x) // 10
//print(p2.x) // 0，p2 不受影响

//let shape1 = Shape(origin: p1, name: "rect")
//let shape2 = shape1 // 引用拷贝
//shape2.origin.x = 99
//print(shape1.origin.x) // 99，两者指向同一对象

//// 枚举关联值
//enum NetworkResult {
//    case success(data: Data)
//    case failure(error: Error)
//    case loading(progress: Double)
//}

//let result = NetworkResult.loading(progress: 0.5)
//switch result {
//    case .loading(let progress):
//        print("加载中：\(progress * 100)%")
//    default:
//        break
//}
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
//// 闭包基本语法
//let add: (Int, Int) -> Int = { a, b in
//    return a + b
//}
//print(add(3, 5)) // 8

//// 尾随闭包 + 简写
//let numbers = [1, 2, 3, 4, 5]
//let squared = numbers.map { $0 * $0 } // [1,4,9,16,25]
//let sum = numbers.reduce(0) { $0 + $1 } // 15

//// 网络请求模拟
//class NetworkManager {
//    var onSuccess: (() -> Void)?
//    var onFailure: ((Error) -> Void)?
//    
//    func fetchData() {
//        // 模拟异步回调
//        DispatchQueue.global().async { [weak self] in
//            guard let self = self else { return }
//            // 请求成功
//            self.onSuccess?()
//        }
//    }
//}

//// 逃逸闭包
//func performAsyncTask(_ completion: @escaping () -> Void) {
//    DispatchQueue.main.async {
//        completion()
//    }
//}

//// 函数作为返回值
//func makeMultiplier(_ factor: Int) -> (Int) -> Int {
//    return { number in
//        return number * factor
//    }
//}
//let triple = makeMultiplier(3)
//print(triple(10)) // 30
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
//protocol Identifiable {
//    associatedtype ID: Hashable
//    var id: ID { get }
//}
//
//protocol Nameable {
//    var name: String { get }
//}
//
//// 协议组合
//typealias UserProtocol = Identifiable & Nameable
//
//struct User: UserProtocol {
//    let id: UUID
//    let name: String
//}
//
//// 协议扩展提供默认实现
//extension Nameable {
//    var displayName: String {
//        return "用户：\(name)"
//    }
//}

//// 泛型约束 + 关联类型
//func printID<T: Identifiable>(_ item: T) {
//    print("ID: \(item.id)")
//}

//let user = User(id: UUID(), name: "Tom")
//printID(user) // ID: 4A2E...
//print(user.displayName) // 用户：Tom

//// 类型擦除示例：AnyHashable
//let mixed: [AnyHashable] = [1, "two", 3.0, UUID()]
//print(mixed.count)

//// some vs any
//func makeUser() -> some Identifiable {
//    return User(id: UUID(), name: "Anonymous")
//}

//let anyUser: any Identifiable = User(id: UUID(), name: "Any")
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
//// 泛型函数
//func swapValues<T>(_ a: inout T, _ b: inout T) {
//    (a, b) = (b, a)
//}
//var x = 5, y = 10
//swapValues(&x, &y) // x=10, y=5

//// 泛型栈
//struct Stack<Element> {
//    private var items: [Element] = []
//    
//    mutating func push(_ item: Element) {
//        items.append(item)
//    }
//    
//    mutating func pop() -> Element? {
//        return items.popLast()
//    }
//}

//// 泛型约束
//func findIndex<T: Equatable>(of valueToFind: T, in array: [T]) -> Int? {
//    for (index, value) in array.enumerated() where value == valueToFind {
//        return index
//    }
//    return nil
//}

//// 条件泛型
//extension Stack where Element: Equatable {
//    func contains(_ element: Element) -> Bool {
//        return items.contains(element)
//    }
//}

//// 泛型 + 协议
//protocol Container {
//    associatedtype Item
//    var count: Int { get }
//    mutating func append(_ item: Item)
//}
//
//struct IntContainer: Container {
//    typealias Item = Int
//    private var items: [Int] = []
//    var count: Int { items.count }
//    mutating func append(_ item: Int) { items.append(item) }
//}
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
//enum FileError: Error {
//    case notFound
//    case permissionDenied
//    case unknown
//}
//
//func readFile(at path: String) throws -> String {
//    guard path.isEmpty == false else {
//        throw FileError.notFound
//    }
//    // 模拟读取
//    if path == "/private" {
//        throw FileError.permissionDenied
//    }
//    return "文件内容"
//}

//// do-catch
//do {
//    let content = try readFile(at: "/tmp/test.txt")
//    print(content)
//} catch FileError.notFound {
//    print("文件不存在")
//} catch FileError.permissionDenied {
//    print("权限不足")
//} catch {
//    print("其他错误：\(error)")
//}

//// try? 返回可选
//let content = try? readFile(at: "/private") // nil
//
//// defer 使用
//func processFile() throws {
//    print("开始处理")
//    defer {
//        print("清理资源")
//    }
//    try readFile(at: "/tmp/test.txt")
//    // 无论是否抛出错误，defer 都会执行
//}
//
//// Result 类型
//func fetchUser(id: Int, completion: (Result<User, Error>) -> Void) {
//    // 模拟网络请求
//    if id > 0 {
//        completion(.success(User(id: UUID(), name: "Tom")))
//    } else {
//        completion(.failure(FileError.notFound))
//    }
//}
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
//class ViewController: UIViewController {
//    var closure: (() -> Void)?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // 错误：闭包强引用 self，self 强引用闭包，循环引用
//        closure = {
//            self.view.backgroundColor = .red
//        }
//        
//        // 正确：使用 weak self
//        closure = { [weak self] in
//            guard let self = self else { return }
//            self.view.backgroundColor = .red
//        }
//        
//        // 使用 unowned self（确保 self 生命周期长于闭包）
//        closure = { [unowned self] in
//            self.view.backgroundColor = .red
//        }
//    }
//    
//    deinit {
//        print("ViewController 释放")
//    }
//}

//// 代理模式
//protocol MyDelegate: AnyObject {
//    func didUpdate()
//}
//
//class Service {
//    weak var delegate: MyDelegate? // 必须 weak，否则循环引用
//}
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
//// 懒加载
//class ImageLoader {
//    lazy var image: UIImage = {
//        print("加载图片")
//        return UIImage(named: "placeholder")!
//    }()
//}

//// 属性观察器
//class Temperature {
//    var celsius: Double = 0 {
//        willSet {
//            print("即将设置温度：\(newValue)°C")
//        }
//        didSet {
//            if celsius > 100 {
//                print("温度过高！")
//            }
//        }
//    }
//}

// 属性包装器
//@propertyWrapper
//struct UserDefault<T> {
//    let key: String
//    let defaultValue: T
//    
//    var wrappedValue: T {
//        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
//        set { UserDefaults.standard.set(newValue, forKey: key) }
//    }
//}
//
//struct AppSettings {
//    @UserDefault(key: "isLoggedIn", defaultValue: false)
//    var isLoggedIn: Bool
//    
//    @UserDefault(key: "username", defaultValue: "Guest")
//    var username: String
//}

//var settings = AppSettings()
//settings.isLoggedIn = true
//print(settings.username) // Guest
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
//// 去重
//let numbers = [1, 2, 3, 2, 1, 4, 5, 4]
//let unique = Array(Set(numbers)) // 无序去重
//let orderedUnique = numbers.reduce(into: [Int]()) { result, value in
//    if !result.contains(value) { result.append(value) }
//} // 有序去重
//
//// 分组
//let users = [("A", 20), ("B", 30), ("C", 20)]
//let grouped = Dictionary(grouping: users) { $0.1 } // [20: [("A",20), ("C",20)], 30: [("B",30)]]

//// 惰性序列
//let lazyFiltered = numbers.lazy.filter { $0 > 2 }.map { $0 * 10 }
//print(Array(lazyFiltered)) // [30, 40, 50]

//// 自定义集合
//struct Countdown: Sequence {
//    let start: Int
//    
//    func makeIterator() -> CountdownIterator {
//        return CountdownIterator(self)
//    }
//}
//
//struct CountdownIterator: IteratorProtocol {
//    var current: Int
//    let start: Int
//    
//    init(_ countdown: Countdown) {
//        self.start = countdown.start
//        self.current = countdown.start
//    }
//    
//    mutating func next() -> Int? {
//        guard current >= 0 else { return nil }
//        defer { current -= 1 }
//        return current
//    }
//}

//for number in Countdown(start: 3) {
//    print(number) // 3,2,1,0
//}
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
// async/await
//func fetchUserData() async throws -> User {
//    // 模拟网络请求
//    try await Task.sleep(nanoseconds: 1_000_000_000)
//    return User(id: UUID(), name: "Async User")
//}

//func loadData() async {
//    do {
//        let user = try await fetchUserData()
//        print("获取到用户：\(user.name)")
//    } catch {
//        print("加载失败：\(error)")
//    }
//}

//// async let 并行执行
//func fetchMultipleData() async throws -> [String] {
//    async let user = fetchUserData()
//    async let anotherUser = fetchUserData()
//    let users = try await [user, anotherUser]
//    return users.map { $0.name }
//}

//// actor 数据隔离
//actor Counter {
//    private var value = 0
//    
//    func increment() {
//        value += 1
//    }
//    
//    func getValue() -> Int {
//        return value
//    }
//}

//let counter = Counter()
//Task {
//    await counter.increment()
//    let value = await counter.getValue()
//    print("计数器：\(value)")
//}

// @MainActor
//@MainActor
//class ViewModel: ObservableObject {
//    @Published var users: [User] = []
//    
//    func load() async {
//        do {
//            let user = try await fetchUserData()
//            users.append(user) // 自动在主线程
//        } catch {
//            // 处理错误
//        }
//    }
//}
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
// Swift 中调用 OC
// 假设 OC 有类 OCNetworkManager
//let manager = OCNetworkManager()
//manager.fetchData { data, error in
//    if let data = data {
//        print("数据：\(data)")
//    }
//}

//// Swift 类暴露给 OC
//@objc class SwiftBridge: NSObject {
//    @objc var name: String
//    @objc init(name: String) {
//        self.name = name
//    }
//    
//    @objc func greet() -> String {
//        return "Hello, \(name)"
//    }
//}

// 在 OC 中使用：
// #import "YourModule-Swift.h"
// SwiftBridge *bridge = [[SwiftBridge alloc] initWithName:@"Tom"];
// [bridge greet];
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
//// 访问控制
//public class PublicClass {
//    private var privateProperty = 0
//    fileprivate func fileprivateMethod() {}
//    public func publicMethod() {}
//}
//
//// final 禁止继承，启用静态派发
//final class FinalClass {
//    func doSomething() {
//        // 静态派发
//    }
//}
//
//// private 方法
//private func helper() {
//    print("私有函数")
//}

//// 性能优化：使用 final 和 private
//final class ViewController: UIViewController {
//    private var dataSource: [String] = []
//    
//    private func setupUI() {
//        // 编译器可优化
//    }
//}
//
//// 测量内存布局
//struct Point {
//    var x: Double
//    var y: Double
//}
//print(MemoryLayout<Point>.size) // 16
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
//// 设计一个通用网络层
//protocol APIRequest {
//    associatedtype Response: Decodable
//    var path: String { get }
//    var method: String { get }
//}

//struct UserRequest: APIRequest {
//    typealias Response = User
//    let path = "/user"
//    let method = "GET"
//}

//class APIClient {
//    func send<T: APIRequest>(_ request: T) async throws -> T.Response {
//        // 构建 URLRequest
//        let url = URL(string: "https://api.example.com\(request.path)")!
//        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = request.method
//        
//        let (data, _) = try await URLSession.shared.data(for: urlRequest)
//        return try JSONDecoder().decode(T.Response.self, from: data)
//    }
//}

//// 使用
//let client = APIClient()
//Task {
//    do {
//        let user = try await client.send(UserRequest())
//        print(user.name)
//    } catch {
//        print("请求失败：\(error)")
//    }
//}
//----------<<<<<<<<<<<


//>>>>>>>>>>>----------
//// 优化：使用 reduce
//func mostFrequentElementOptimized<T: Hashable>(in array: [T]) -> T? {
//    let frequency = array.reduce(into: [T: Int]()) { counts, element in
//        counts[element, default: 0] += 1
//    }
//    return frequency.max { $0.value < $1.value }?.key
//}
//----------<<<<<<<<<<<
