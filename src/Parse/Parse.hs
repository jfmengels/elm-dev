{-# OPTIONS_GHC -Wall -fno-warn-unused-do-bind #-}
module Parse.Parse (program) where

import qualified Data.Text as Text
import Data.Text (Text)

import qualified AST.Declaration as Decl
import qualified AST.Module as Module
import qualified AST.Module.Name as ModuleName
import qualified Elm.Package as Package
import Parse.Helpers
import qualified Parse.Module as Parse (header)
import qualified Parse.Declaration as Parse (declaration)
import qualified Validate



-- PROGRAM


program :: Package.Name -> Text -> Validate.Result wrn Module.Valid
program pkgName src =
  case run (chompProgram pkgName) src of
    Right modul ->
        Validate.validate modul

    Left err ->
        error ("TODO program parse error\n" ++ show err ++ "\n" ++ Text.unpack (Text.take 100 src))


chompProgram :: Package.Name -> Parser Module.Source
chompProgram pkgName =
  do  (Module.Header tag name exports settings docs imports) <- Parse.header
      decls <- chompDeclarations []
      endOfFile
      let moduleName = ModuleName.Canonical pkgName name
      let source = Module.Source tag settings docs exports imports decls
      return (Module.Module moduleName "" source)


chompDeclarations :: [Decl.Source] -> Parser [Decl.Source]
chompDeclarations decls =
  do  (decl, _, pos) <- Parse.declaration
      oneOf
        [ do  checkFreshline pos
              chompDeclarations (decl:decls)
        , return (reverse (decl:decls))
        ]
