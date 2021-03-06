////
///  SeeAllCategoriesCellPresenterSpec.swift
//

@testable import Ello
import Quick
import Nimble


class SeeAllCategoriesCellPresenterSpec: QuickSpec {
    override func spec() {
        describe("SeeAllCategoriesCellPresenter") {
            it("configures a CategoryCell") {
                let cell: CategoryCell = CategoryCell()
                let item: StreamCellItem = StreamCellItem(type: .SeeAllCategories)

                SeeAllCategoriesCellPresenter.configure(cell, streamCellItem: item, streamKind: .CurrentUserStream, indexPath: NSIndexPath(forItem: 0, inSection: 0), currentUser: nil)

                expect(cell.title) == "See All"
                expect(cell.highlight) == CategoryCell.Highlight.White
            }
        }
    }
}
