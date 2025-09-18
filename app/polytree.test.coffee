# Basic Polytree tests

{ Polytree } = require "../polytree.bundle.js"

describe "Polytree", ->

    it "should create instance without parameters", ->

        polytree = new Polytree()
        expect(polytree).toBeDefined()
        expect(polytree.isPolytree).toBe(true)

    it "should have CSG instance methods", ->

        polytree = new Polytree()
        expect(typeof polytree.unite).toBe("function")
        expect(typeof polytree.subtract).toBe("function")
        expect(typeof polytree.intersect).toBe("function")
