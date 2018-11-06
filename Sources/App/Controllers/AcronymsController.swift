import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    
    func boot(router: Router) throws {
        
        //Create a new route group for the path /api/acronyms
        let acronymsRoutes = router.grouped("api", "acronyms")
        
        //Return all acronyms
        acronymsRoutes.get(use: getAllHandler)
        
        //Process POST request
        //acronymsRoutes.post(use: createHandler)
        acronymsRoutes.post(Acronym.self, use: createHandler)
        
        //Process GET request for a single acronym
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        
        //Process PUT request
        acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        
        //Process DELETE request
        acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
        
        //Process SEARCH request
        acronymsRoutes.get("search", use: searchHandler)
        
        //Obtain the first acronym in the database
        acronymsRoutes.get("first", use: getFirstHandler)
        
        //Sorted request
        acronymsRoutes.get("sorted", use: sortedHandler)
        
        //HTTP GET request to /api/acronyms/<Acronym ID>/user to getUserHandler
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        
        //HTTP POST request to /api/acronyms/<ACRONYM_ID>/categories/<CATEGORY_ID>
        acronymsRoutes.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        
        //HTTP GET request to /api/acronyms/<ACRONYM_ID>/categories
        acronymsRoutes.get(Acronym.parameter, "categories", use: getCategoriesHandler)
        
        //HTTP DELETE request to /api/acronyms/<ACRONYM_ID>/categories/<CATEGORY_ID>
        acronymsRoutes.delete(Acronym.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
    }
    
    //Add a new route handler
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
            return acronym.save(on: req)
    }
    
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self)) { acronym, updateAcronym in
            acronym.short = updateAcronym.short
            acronym.long = updateAcronym.long
            acronym.userID = updateAcronym.userID
            return acronym.save(on: req)
        }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
    
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at:"term"] else {
            throw Abort(.badRequest)
        }
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }.all()
    }
    
    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req).first().map(to: Acronym.self) { acronym in
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            return acronym
        }
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }
    
    func getUserHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(Acronym.self).flatMap(to: User.self) { acronym in
            acronym.user.get(on: req)
        }
    }
    
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self)) { acronym, category in
            return acronym.categories.attach(category, on: req).transform(to: .created)
        }
    }
    
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Acronym.self).flatMap(to: [Category].self) { acronym in
            try acronym.categories.query(on: req).all()
        }
    }
    
    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self)) { acronym, category in
            return acronym.categories.detach(category, on: req).transform(to: .noContent)
        }
    }
}
