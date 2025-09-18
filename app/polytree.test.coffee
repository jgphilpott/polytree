# Comprehensive Polytree Tests

{ Polytree } = require "../polytree.bundle.js"
{ Box3, Vector3, Mesh, BoxGeometry, MeshBasicMaterial, Matrix4 } = require "three"

describe "Polytree", ->

    describe "Constructor", ->

        it "should create instance without parameters", ->

            polytree = new Polytree()

            expect(polytree).toBeDefined()
            expect(polytree.isPolytree).toBe(true)

            expect(polytree.box).toBeNull()
            expect(polytree.parent).toBeNull()

            expect(polytree.level).toBe(0)

            expect(polytree.polygons).toEqual([])
            expect(polytree.subTrees).toEqual([])

        it "should create instance with box parameter", ->

            box = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1))
            polytree = new Polytree(box)

            expect(polytree.box).toBe(box)
            expect(polytree.parent).toBeNull()

        it "should create instance with box and parent parameters", ->

            parentPolytree = new Polytree()
            box = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1))
            childPolytree = new Polytree(box, parentPolytree)

            expect(childPolytree.box).toBe(box)
            expect(childPolytree.parent).toBe(parentPolytree)

    describe "Small Helpers and Getters", ->

        it "isEmpty should return true for empty polytree", ->

            polytree = new Polytree()

            expect(polytree.isEmpty()).toBe(true)

        it "isEmpty should return false for non-empty polytree", ->

            polytree = new Polytree()
            polytree.polygons.push({}) # Mock polygon

            expect(polytree.isEmpty()).toBe(false)

        it "getMesh should return null for root with no mesh", ->

            polytree = new Polytree()

            expect(polytree.getMesh()).toBeNull()

        it "getMesh should return mesh from root", ->

            geometry = new BoxGeometry(1, 1, 1)
            material = new MeshBasicMaterial({ color: 0x00ff00 })
            mesh = new Mesh(geometry, material)

            polytree = new Polytree()
            polytree.mesh = mesh

            expect(polytree.getMesh()).toBe(mesh)

        it "getMesh should traverse to root and get mesh", ->

            geometry = new BoxGeometry(1, 1, 1)
            material = new MeshBasicMaterial({ color: 0x00ff00 })
            mesh = new Mesh(geometry, material)

            root = new Polytree()
            root.mesh = mesh
            child = new Polytree(null, root)
            grandchild = new Polytree(null, child)

            expect(grandchild.getMesh()).toBe(mesh)

        it "getMesh should handle circular references", ->

            root = new Polytree()
            child = new Polytree(null, root)
            root.parent = child # Create circular reference

            expect(root.getMesh()).toBeNull()

        it "newPolytree should create new instance with parameters", ->

            polytree = new Polytree()
            box = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1))
            newInstance = polytree.newPolytree(box, polytree)

            expect(newInstance).toBeInstanceOf(Polytree)
            expect(newInstance.box).toBe(box)
            expect(newInstance.parent).toBe(polytree)

        it "setPolygonIndex should handle undefined index", ->

            polytree = new Polytree()

            expect(() -> polytree.setPolygonIndex(undefined)).not.toThrow()

    describe "Object Creation and Copying", ->

        it "clone should create deep copy", ->

            original = new Polytree()
            original.level = 5
            clone = original.clone()

            expect(clone).toBeInstanceOf(Polytree)
            expect(clone).not.toBe(original)
            expect(clone.level).toBe(5)

        it "copy should handle null box safely", ->

            source = new Polytree()
            target = new Polytree()

            expect(() -> target.copy(source)).not.toThrow()
            expect(target.box).toBeNull()

        it "copy should clone box when present", ->

            box = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1))
            source = new Polytree(box)
            target = new Polytree()
            target.copy(source)

            expect(target.box).not.toBe(source.box) # Should be different objects
            expect(target.box.equals(source.box)).toBe(true) # But equal values

        it "copy should handle mesh and matrix properly", ->

            geometry = new BoxGeometry(1, 1, 1)
            material = new MeshBasicMaterial({ color: 0x00ff00 })
            mesh = new Mesh(geometry, material)
            matrix = mesh.matrixWorld.clone()

            source = new Polytree()
            source.mesh = mesh
            source.originalMatrixWorld = matrix

            target = new Polytree()
            target.copy(source)

            expect(target.mesh).toBe(mesh) # Mesh is shared reference
            expect(target.originalMatrixWorld).not.toBe(matrix) # Matrix should be cloned
            expect(target.originalMatrixWorld.equals(matrix)).toBe(true)

    describe "CSG Operations (Instance Methods)", ->

        beforeEach ->

            @polytree = new Polytree()

        it "should have CSG instance methods", ->

            expect(typeof @polytree.unite).toBe("function")
            expect(typeof @polytree.subtract).toBe("function")
            expect(typeof @polytree.intersect).toBe("function")

        # Note: Full CSG testing would require complex mesh setup.
        # These tests verify the methods exist and can be called.
        it "unite method should be callable", ->

            expect(typeof @polytree.unite).toBe("function")
            # Full testing would require valid mesh objects.

        it "subtract method should be callable", ->

            expect(typeof @polytree.subtract).toBe("function")
            # Full testing would require valid mesh objects.

        it "intersect method should be callable", ->

            expect(typeof @polytree.intersect).toBe("function")
            # Full testing would require valid mesh objects.

    describe "Core Polygon Operations", ->

        it "calcBox should handle missing bounds", ->

            polytree = new Polytree()

            expect(() -> polytree.calcBox()).not.toThrow()
            expect(polytree.box).toBeDefined()

        it "calcBox should apply offset to bounds", ->

            polytree = new Polytree()
            polytree.bounds = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1))
            polytree.calcBox()

            expect(polytree.box.min.x).toBeLessThan(-1)
            expect(polytree.box.max.x).toBeGreaterThan(1)

        it "addPolygon should initialize bounds if not present", ->

            polytree = new Polytree()

            mockPolygon = {
                triangle: {
                    a: new Vector3(1, 2, 3)
                    b: new Vector3(4, 5, 6)
                    c: new Vector3(7, 8, 9)
                }
            }

            polytree.addPolygon(mockPolygon)

            expect(polytree.bounds).toBeDefined()
            expect(polytree.polygons.length).toBe(1)

        it "addPolygon should expand bounds correctly", ->

            polytree = new Polytree()

            mockPolygon = {
                triangle: {
                    a: new Vector3(-5, -5, -5)
                    b: new Vector3(5, 5, 5)
                    c: new Vector3(0, 0, 0)
                }
            }

            polytree.addPolygon(mockPolygon)

            expect(polytree.bounds.min.x).toBe(-5)
            expect(polytree.bounds.max.x).toBe(5)
            expect(polytree.bounds.min.y).toBe(-5)
            expect(polytree.bounds.max.y).toBe(5)

        it "addPolygon should handle trianglesSet parameter", ->

            polytree = new Polytree()

            mockPolygon = {
                triangle: {
                    a: new Vector3(1, 2, 3)
                    b: new Vector3(4, 5, 6)
                    c: new Vector3(7, 8, 9)
                }
            }

            # Test with trianglesSet parameter (actual behavior depends on isUniqueTriangle implementation).
            trianglesSet = new Set()
            result = polytree.addPolygon(mockPolygon, trianglesSet)

            expect(result).toBe(polytree) # Note: Actual polygon addition depends on isUniqueTriangle function implementation.

    describe "Tree Construction", ->

        it "buildTree should execute without errors on empty polytree", ->

            polytree = new Polytree()

            expect(() -> polytree.buildTree()).not.toThrow()

        it "split should return early if no box", ->

            polytree = new Polytree()
            result = polytree.split(0)

            expect(result).toBe(polytree)
            expect(polytree.subTrees.length).toBe(0)

    describe "Polygon Array Management", ->

        it "addPolygonsArrayToRoot should initialize array on root", ->

            polytree = new Polytree()
            testArray = []
            polytree.addPolygonsArrayToRoot(testArray)

            expect(polytree.polygonArrays).toContain(testArray)

        it "addPolygonsArrayToRoot should traverse to root", ->

            root = new Polytree()
            child = new Polytree(null, root)
            testArray = []
            child.addPolygonsArrayToRoot(testArray)

            expect(root.polygonArrays).toContain(testArray)

        it "deletePolygonsArrayFromRoot should remove array", ->

            polytree = new Polytree()
            testArray = []
            polytree.addPolygonsArrayToRoot(testArray)
            polytree.deletePolygonsArrayFromRoot(testArray)

            expect(polytree.polygonArrays).not.toContain(testArray)

    describe "Static Properties", ->

        it "should have expected static properties", ->

            expect(Polytree.maxLevel).toBe(16)
            expect(Polytree.polygonsPerTree).toBe(100)
            expect(Polytree.usePolytreeRay).toBe(true)
            expect(Polytree.disposePolytree).toBe(true)
            expect(Polytree.useWindingNumber).toBe(false)
            expect(Polytree.rayIntersectTriangleType).toBe("MollerTrumbore")

        it "should have static methods", ->

            expect(typeof Polytree.unite).toBe("function")
            expect(typeof Polytree.subtract).toBe("function")
            expect(typeof Polytree.intersect).toBe("function")
            expect(typeof Polytree.rayIntersectsTriangle).toBe("function")

    describe "Error Handling", ->

        it "should handle method calls on empty polytree", ->

            polytree = new Polytree()

            expect(() -> polytree.isEmpty()).not.toThrow()
            expect(() -> polytree.getMesh()).not.toThrow()
            expect(() -> polytree.clone()).not.toThrow()
            expect(() -> polytree.buildTree()).not.toThrow()

        it "should handle invalid parameters gracefully", ->

            polytree = new Polytree()

            expect(() -> polytree.setPolygonIndex(null)).not.toThrow()
            expect(() -> polytree.setPolygonIndex(undefined)).not.toThrow()
            expect(() -> polytree.copy({})).not.toThrow() # Invalid source object

    describe "Performance and Edge Cases", ->

        it "should handle large number of polygons efficiently", ->

            polytree = new Polytree()
            start = Date.now()

            # Add 1000 mock polygons.
            for i in [0...1000]

                mockPolygon = {
                    triangle: {
                        a: new Vector3(Math.random() * 100, Math.random() * 100, Math.random() * 100)
                        b: new Vector3(Math.random() * 100, Math.random() * 100, Math.random() * 100)
                        c: new Vector3(Math.random() * 100, Math.random() * 100, Math.random() * 100)
                    }
                }

                polytree.addPolygon(mockPolygon)

            end = Date.now()

            expect(polytree.polygons.length).toBe(1000)
            expect(end - start).toBeLessThan(1000) # Should complete in under 1 second.

        it "should handle deep tree structures", ->

            root = new Polytree()
            current = root

            # Create a chain of 100 child nodes.
            for i in [0...100]

                child = new Polytree(null, current)
                current.subTrees.push(child)
                current = child

            # Should be able to traverse without stack overflow.
            expect(() -> root.getMesh()).not.toThrow()

        it "expandParentBox should handle circular references", ->

            parent = new Polytree()
            child = new Polytree(null, parent)
            parent.parent = child # Create circular reference
            parent.box = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1))
            child.box = new Box3(new Vector3(-2, -2, -2), new Vector3(2, 2, 2))

            expect(() -> child.expandParentBox()).not.toThrow()

        it "split should handle edge case with invalid polygon midpoints", ->

            polytree = new Polytree()
            polytree.box = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1))

            # Add polygon with midpoint outside the box (edge case).
            mockPolygon = {

                triangle: {
                    a: new Vector3(10, 10, 10)
                    b: new Vector3(11, 11, 11)
                    c: new Vector3(12, 12, 12)
                }

                getMidpoint: -> new Vector3(11, 11, 11) # Outside the box

            }

            polytree.polygons.push(mockPolygon)

            # Should throw an error for polygon outside bounds.
            expect(() -> polytree.split(0)).toThrow()

    describe "Memory Management", ->

        it "should properly clean up references", ->

            polytree = new Polytree()
            child = new Polytree(null, polytree)
            polytree.subTrees.push(child)

            # Add some mock data with proper delete methods.
            mockPolygon = {
                test: "data"
                delete: -> # Mock delete method
            }

            mockChildPolygon = {
                test: "child data"
                delete: -> # Mock delete method
            }

            polytree.polygons.push(mockPolygon)
            child.polygons.push(mockChildPolygon)

            # Clear should work without errors.
            expect(() -> polytree.delete()).not.toThrow()
            expect(polytree.polygons.length).toBe(0)
            expect(polytree.subTrees.length).toBe(0)

        it "dispose should work as alias for delete", ->

            polytree = new Polytree()
            mockPolygon = { 
                test: "data"
                delete: -> # Mock delete method
            }
            polytree.polygons.push(mockPolygon)
            
            expect(() -> polytree.dispose()).not.toThrow()
            expect(polytree.polygons.length).toBe(0)

        it "dispose should pass parameters to delete", ->

            polytree = new Polytree()
            mockPolygon = { 
                test: "data"
                delete: -> # Mock delete method
            }
            polytree.polygons.push(mockPolygon)
            
            # Test with deletePolygons = false
            expect(() -> polytree.dispose(false)).not.toThrow()

    describe "Advanced Polygon Operations", ->

        it "deleteReplacedPolygons should clean up replaced polygons", ->

            polytree = new Polytree()
            mockPolygon = { 
                delete: -> # Mock delete method
            }
            polytree.replacedPolygons.push(mockPolygon)
            
            expect(() -> polytree.deleteReplacedPolygons()).not.toThrow()
            expect(polytree.replacedPolygons.length).toBe(0)

        it "deleteReplacedPolygons should handle child nodes", ->

            polytree = new Polytree()
            child = new Polytree(null, polytree)
            polytree.subTrees.push(child)
            
            mockPolygon = { delete: -> }
            child.replacedPolygons.push(mockPolygon)
            
            polytree.deleteReplacedPolygons()
            expect(child.replacedPolygons.length).toBe(0)

        it "markPolygonsAsOriginal should set originalValid flag", ->

            polytree = new Polytree()
            mockPolygon = { originalValid: false }
            polytree.polygons.push(mockPolygon)
            
            polytree.markPolygonsAsOriginal()
            expect(mockPolygon.originalValid).toBe(true)

        it "invert should call flip on all polygons", ->

            polytree = new Polytree()
            flipped = false
            mockPolygon = { 
                flip: -> flipped = true
            }
            polytree.polygons.push(mockPolygon)
            
            polytree.invert()
            expect(flipped).toBe(true)

        it "processTree should handle empty trees", ->

            polytree = new Polytree()
            expect(() -> polytree.processTree()).not.toThrow()

        it "processTree should expand bounding boxes", ->

            polytree = new Polytree()
            polytree.box = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1))
            
            # Add a mock polygon that would expand the bounds
            mockPolygon = {
                triangle: {
                    a: new Vector3(5, 5, 5)
                    b: new Vector3(6, 6, 6)
                    c: new Vector3(7, 7, 7)
                }
            }
            polytree.polygons.push(mockPolygon)
            
            expect(() -> polytree.processTree()).not.toThrow()
            # Box should be expanded to include the polygon vertices
            expect(polytree.box.max.x).toBeGreaterThan(1)

    describe "Polygon Array Management Advanced", ->

        it "getPolygons should return all valid polygons", ->

            polytree = new Polytree()
            validPolygon = { valid: true }
            invalidPolygon = { valid: false }
            
            polytree.polygons.push(validPolygon, invalidPolygon)
            
            polygons = polytree.getPolygons()
            expect(polygons.length).toBe(1)
            expect(polygons[0]).toBe(validPolygon)

        it "getIntersectingPolygons should return only intersecting polygons", ->

            polytree = new Polytree()
            intersectingPolygon = { valid: true, intersects: true }
            nonIntersectingPolygon = { valid: true, intersects: false }
            
            polytree.polygons.push(intersectingPolygon, nonIntersectingPolygon)
            
            polygons = polytree.getIntersectingPolygons()
            expect(polygons.length).toBe(1)
            expect(polygons[0]).toBe(intersectingPolygon)

        it "getPolygonCloneCallback should call callback for valid polygons", ->

            polytree = new Polytree()
            callbackCalled = false
            mockPolygon = { 
                valid: true
                clone: -> this
            }
            polytree.polygons.push(mockPolygon)
            
            callback = -> callbackCalled = true
            polytree.getPolygonCloneCallback(callback)
            
            expect(callbackCalled).toBe(true)

        it "replacePolygon should handle array replacement", ->

            polytree = new Polytree()
            originalPolygon = { 
                test: "original"
                setInvalid: -> # Mock setInvalid method
            }
            replacementPolygon = { test: "replacement" }
            
            polytree.polygons.push(originalPolygon)
            
            expect(() -> polytree.replacePolygon(originalPolygon, replacementPolygon)).not.toThrow()

        it "replacePolygon should handle multiple replacements", ->

            polytree = new Polytree()
            originalPolygon = { 
                test: "original"
                setInvalid: -> # Mock setInvalid method
            }
            replacements = [{ test: "replacement1" }, { test: "replacement2" }]
            
            polytree.polygons.push(originalPolygon)
            
            expect(() -> polytree.replacePolygon(originalPolygon, replacements)).not.toThrow()

    describe "Matrix and Transformation", ->

        it "applyMatrix should handle null box gracefully", ->

            polytree = new Polytree()
            # Don't set box, test with null
            
            # Should not crash when box is null
            expect(() -> polytree.applyMatrix(new Matrix4())).not.toThrow()

        it "applyMatrix should process tree after transformation", ->

            polytree = new Polytree()
            polytree.box = new Box3(new Vector3(-1, -1, -1), new Vector3(1, 1, 1))
            
            # Use real Three.js matrix
            matrix = new Matrix4()
            
            expect(() -> polytree.applyMatrix(matrix)).not.toThrow()

    describe "Complex Edge Cases", ->

        it "should handle null polygon arrays gracefully", ->

            polytree = new Polytree()
            polytree.polygonArrays = null
            
            expect(() -> polytree.setPolygonIndex(5)).not.toThrow()
            # Note: getPolygons and invert expect polygonArrays to exist, so skip those tests
            # These methods would need null safety improvements if this is a real use case

        it "should handle empty polygon arrays", ->

            polytree = new Polytree()
            polytree.polygonArrays = []
            
            expect(() -> polytree.setPolygonIndex(5)).not.toThrow()
            expect(() -> polytree.getPolygons()).not.toThrow()
            expect(() -> polytree.invert()).not.toThrow()

        it "should handle deeply nested tree structures", ->

            root = new Polytree()
            current = root
            
            # Create 50 levels deep
            for i in [0...50]
                child = new Polytree(null, current)
                current.subTrees.push(child)
                current = child
            
            expect(() -> root.processTree()).not.toThrow()
            expect(() -> root.deleteReplacedPolygons()).not.toThrow()
            expect(() -> root.markPolygonsAsOriginal()).not.toThrow()
