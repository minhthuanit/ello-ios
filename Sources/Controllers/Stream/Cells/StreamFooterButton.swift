////
///  StreamFooterButton.swift
//

public class StreamFooterButton: UIButton {

    var attributedText: NSMutableAttributedString = NSMutableAttributedString(string: "")

    func setButtonTitleWithPadding(title: String?, titlePadding: CGFloat = 4.0, contentPadding: CGFloat = 5.0) {

        if let title = title {
            setButtonTitle(title, color: UIColor.greyA(), forState: .Normal)
            setButtonTitle(title, color: UIColor.blackColor(), forState: .Highlighted)
            setButtonTitle(title, color: UIColor.blackColor(), forState: .Selected)
        }

        titleEdgeInsets = UIEdgeInsets(top: 0.0, left: titlePadding, bottom: 0.0, right: -(titlePadding))
        contentEdgeInsets = UIEdgeInsets(top: 0.0, left: contentPadding, bottom: 0.0, right: contentPadding)
        sizeToFit()
    }

    private func setButtonTitle(title: String, color: UIColor, forState state: UIControlState) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Center

        let attributes = [
            NSFontAttributeName : UIFont.defaultFont(),
            NSForegroundColorAttributeName : color,
            NSParagraphStyleAttributeName : paragraphStyle
        ]
        attributedText = NSMutableAttributedString(string: title, attributes: attributes)

        contentHorizontalAlignment = .Center
        self.titleLabel?.textAlignment = .Center
        self.setAttributedTitle(attributedText, forState: state)
    }

    override public func sizeThatFits(size: CGSize) -> CGSize {
        let size = super.sizeThatFits(size)
        return CGSize(width: max(44.0, size.width), height: 44.0)
    }
}
