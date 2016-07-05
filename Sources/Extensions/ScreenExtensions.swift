extension UIWindow {
    class var mainWindow: UIWindow {
        return UIApplication.sharedApplication().keyWindow ?? UIWindow()
    }

    class func windowBounds() -> CGRect {
        return mainWindow.bounds
    }

    class func windowSize() -> CGSize {
        return windowBounds().size
    }

    class func windowWidth() -> CGFloat {
        return windowSize().width
    }

    class func windowHeight() -> CGFloat {
        return windowSize().height
    }

}


public class Window {
    static public func isWide(width: CGFloat) -> Bool {
        return width > 1000
    }
    static public var width: CGFloat { return UIWindow.mainWindow.frame.size.width }
}
