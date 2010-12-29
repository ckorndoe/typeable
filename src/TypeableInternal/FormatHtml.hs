{-# OPTIONS -XFlexibleInstances -XNoMonomorphismRestriction #-}
{-# LANGUAGE OverloadedStrings, ScopedTypeVariables #-}

module TypeableInternal.FormatHtml where

import Typeable.Cb5ba7ec44dbb4236826c6ef6bc4837e4
import Typeable.T421496848904471ea3197f25e2a02b72
import Typeable.Cc6ebaa9f4cdc4068894d1ffaef5a7a83
import Typeable.T9e2e1e478e094a8abe5507f8574ac91f

import Prelude
import Data.String
import Data.List
import Numeric
import qualified Prelude as P
import Control.Monad (forM_)

import Text.Blaze.Html5
import Text.Blaze.Html5.Attributes
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import qualified Data.Text as T
import Data.Time.Calendar

import Text.Blaze.Renderer.Utf8

import qualified Data.ByteString.Lazy as L

import System.Process
import Data.Function

import TypeableInternal.InternalTypeDefs
import qualified Network.URL as U
import Data.Monoid (mconcat, mempty)
import qualified Data.List
import qualified Data.Map as M
import qualified Data.Set as S

import TypeableInternal.Context

encapsulate t = docTypeHtml $ do 
                  H.head $ do
                    H.title "typeable.org"
                    H.meta ! httpEquiv "Content-Type" ! content "text/html; charset=utf-8"
                    H.link ! href (textValue "../static/style.css") ! rel (textValue "stylesheet") ! type_ (textValue "text/css")
                    H.link ! href (textValue "http://fonts.googleapis.com/css?family=Vollkorn") ! rel (textValue "stylesheet") ! type_ (textValue "text/css")
                  body t

class Htmlize a where
  htmlize :: a -> (Context Html)

instance Htmlize Zero where
  htmlize = undefined

instance PeanoNumber a => Htmlize (Succ a) where
  htmlize x = return $ H.span ! class_ "variable bound" $ string $ return (toEnum (97 + fromEnum x) :: Char)

instance Htmlize Namespace where
  htmlize x = do ns' <- mapM (htmlize . snd) ns >>= return . zip (Data.List.map fst ns)
                 ts' <- mapM humanify ts        >>= return . sortBy (compare `on` snd) . zip ts
                 cs' <- mapM humanify cs        >>= return . sortBy (compare `on` snd) . zip cs
                 return $ H.ul $ do mconcat $ Data.List.map (\(u,n)-> H.li $ H.a ! A.href (stringValue $ "class/"++(show u)) $ H.span ! A.class_ "class" $ string n) cs'
                                    mconcat $ Data.List.map (\(u,n)-> H.li $ H.a ! A.href (stringValue $ "type/"++(show u))  $ H.span ! A.class_ "type"  $ string n) ts'
                                    mconcat $ Data.List.map (\(f,s)-> H.li (string (show f) >> s)) ns' 

    where
      ts = S.toList (nstypes   x)
      cs = S.toList (nsclasses x)
      ns = M.toList (subspaces x)

instance PeanoNumber k => Htmlize (Annotation k) where
  htmlize (Plain t)       = return $         text t

instance (Htmlize k, PeanoNumber k) => Htmlize (Constraint k) where
  htmlize (Constraint i ts) = do ts' <- htmlize ts
                                 i'  <- humanify i
                                 return $ do H.a ! href (stringValue $ "../class/"++(show i)) $ H.span ! class_ "class" $ string i'
                                             preEscapedText "&nbsp;"
                                             ts'

instance (PeanoNumber k, Htmlize k) => Htmlize (Field k) where
  htmlize (Field n s t) = do t' <- htmlize t
                             s' <- htmlize s
                             return $ tr $ do td ! class_ "function"   $ string (show n)
                                              td ! class_ "type"       $ t'
                                              td ! class_ "annotation" $ s'

instance (PeanoNumber k, Htmlize k) => Htmlize (Method k) where
  htmlize (Method n t s) = do t' <- htmlize t
                              s' <- htmlize s
                              return $ tr $ do td ! class_ "function" $ string (show n)
                                               td ! class_ "type"       $ t'
                                               td ! class_ "annotation" $ s'

instance (PeanoNumber k, Htmlize k) => Htmlize (Constructor k) where
  htmlize (Constructor n s cs) = do s'  <- htmlize s
                                    cs' <- htmlize cs
                                    return $ do tr $ do td ! class_ "constructor" ! rowspan (stringValue $ show (P.length cs + 1)) $ string (show n)
                                                        td ! class_ "annotation"  ! colspan "3" $ s'
                                                cs'

instance (PeanoNumber k, Htmlize k) => Htmlize (Type k) where
  htmlize x = htmlize' x False
    where 
      htmlize' (DataType i) _ = humanify i >>= return . (a ! href (stringValue $ show i)) . string
      htmlize' (Variable v) _ = htmlize v
      htmlize' (Forall t)   _ = do let vs = domain :: [k] 
                                   t' <- htmlize t 
                                   v' <- htmlize (Next $ last vs :: (Succ k))
                                   return $ do "\x2200"
                                               v'
                                               preEscapedString ":&nbsp;"
                                               t'
      htmlize' (Application
                 (Application 
                   (DataType (UUID 107557859644440974686449305308309621121)) 
                   t1
                 ) 
                 t2
               )            w = do t1' <- htmlize' t1 True 
                                   t2' <- htmlize  t2
                                   return $ do if w then "(" else ""
                                               t1'
                                               a ! href "/type/50eae3e85d2d42c88754b026cc360981" $ preEscapedString "&#x202F;\x2192&#x202F;"
                                               t2'
                                               if w then ")" else ""
      htmlize' (Application t1 t2) w | t1 == DataType "0ba85f3f10099c75d4b696d0cf944e09" = do t2' <- htmlize t2
                                                                                              return $ do a ! href (stringValue $ show $ typeRef t1) $ "["
                                                                                                          t2'
                                                                                                          a ! href (stringValue $ show $ typeRef t1) $ "]"
                                     | t1 == DataType "7af30cce93724981a16a80f3f193dc33" = do t2' <- htmlize t2
                                                                                              return $ do a ! href (stringValue $ show $ typeRef t1) $ "{"
                                                                                                          t2'
                                                                                                          a ! href (stringValue $ show $ typeRef t1) $ "}"
                                     | otherwise = do t1' <- htmlize' t1 False
                                                      t2' <- htmlize' t2 True
                                                      return $ do if w then string "(" else mempty
                                                                  t1'
                                                                  preEscapedString "&nbsp;"
                                                                  t2'
                                                                  if w then string ")" else mempty

instance Htmlize UUID where
  htmlize x = return $ H.a ! href (stringValue $ (show x)) ! class_ "fixedwidth" $ string (show x)

instance Htmlize a => Htmlize [a] where
  htmlize xs = do xs' <- mapM htmlize xs
                  return $ mconcat xs'

instance Htmlize Person where
  htmlize x  = return $ string $ personName x

kind :: (PeanoNumber a) => Binding a Kind' c -> Kind'
kind (Expression _) = Concrete'
kind (Bind k x    ) = Application' k (kind x)
                              
variables :: Kind' -> [Html]
variables x         = f 0 x
                      where
                        f _ Concrete'         = []
                        f n (Application' _ y) = (string [toEnum ((fromEnum 'a') + n)]):(f (n+1) y)

toHtml    :: (PeanoNumber a, Htmlize a) => Binding a Kind' Type' -> Context (Html, Html, Html)
toHtml (Expression x) = do a  <- htmlize $ semantics x 
                           bs <- mapM htmlize $ S.toList $ constraints x
                           let b = mconcat $ Data.List.intersperse (string "|") bs
                           c  <- case constructors x of
                                   Nothing -> return $ tr $ td ! colspan "4" $ "This is an abstract type. Its possible values are described above."
                                   Just y  -> htmlize y
                           return (a,b,c)
toHtml (Bind _ x)     = toHtml x

instance Htmlize T.Text where
  htmlize = return . text

instance Htmlize (Definition Type') where
  htmlize x  = do author'              <- case author x of
                                            Nothing -> return "PublicDomain"
                                            Just a  -> htmlize a
                  maintainer'          <- htmlize (maintainer x)
                  (semantics', constraints', constructors') <- toHtml (structure x)
                  return $   do H.div ! A.id "meta" $ do
                                  H.h1 "Meta"
                                  table $ do tr $ do td "Name"
                                                     td ! class_ "type" $ H.a ! A.href "" $ (string $ show $ TypeableInternal.InternalTypeDefs.name x)
                                             tr $ do td "UUID"
                                                     td $ string $ show (identifier x)
                                             tr $ do td "Author"
                                                     td author'
                                             tr $ do td "Maintainer"
                                                     td maintainer' 
                                             tr $ do td "Created"
                                                     td (string $ show (creationTime x))
                                             tr $ do td "Modified"
                                                     td (string $ show (modificationTime x))
                                H.div ! A.id "exports" $ do
                                  H.h1 "Export"
                                  H.ul $ do H.li $ H.a ! A.href (stringValue ((show (identifier x)) ++ "?format=haskell")) $ "Haskell" 
                                            H.li $ H.a ! A.href (stringValue ((show (identifier x)) ++ "?format=haskell-boot")) $ "Haskell-Boot" 
                                H.div ! A.id "description" $ do
                                  H.h1 "Description"
                                  H.div ! class_ "annotation" $ semantics'
                                H.div ! A.id "structure" $ do
                                  H.h1 "Structure"
                                  H.table $ do
                                    H.tr $ td ! colspan "4" ! class_ "type large" $ do H.a ! A.href "" $ string $ show (TypeableInternal.InternalTypeDefs.name x)
                                                                                       preEscapedString "&nbsp;"
                                                                                       mconcat (Data.List.intersperse (preEscapedString "&nbsp;") (variables $ kind $ structure x))
                                    H.tr $ td ! colspan "4" ! class_ "constraints" $ constraints'
                                    constructors'

instance Htmlize (Definition Class') where
  htmlize = undefined
  {--
  htmlize x  = do a  <- htmlize (classSemantics x)
                  author' <- case classAuthor x of
                               Nothing -> return "PublicDomain"
                               Just a  -> htmlize a
                  maintainer' <- htmlize (classMaintainer x)
                  bs <- mapM htmlize $ S.toList (classConstraints x)
                  let bs' = Data.List.intersperse (string " | ") bs 
                  let b   = mconcat bs'
                  let vars = domain :: [k]
                  bv <- mapM htmlize vars
                  ms <- mapM htmlize (classMethods x)
                  return $   do H.div ! A.id "meta" $ do
                                  H.h1 "Meta"
                                  table $ do
                                    tr $ do td "Name"
                                            td ! class_ "type" $ H.a ! A.href "" $ (string $ show $ className x)
                                    tr $ do td "UUID"
                                            td $ string $ show (classIdentifier x)
                                    tr $ do td "Author"
                                            td author'
                                    tr $ do td "Maintainer"
                                            td maintainer' 
                                    tr $ do td "Created"
                                            td (string $ show (classCreated x))
                                    tr $ do td "Modified"
                                            td (string $ show (classModified x))
                                H.div ! A.id "exports" $ do
                                  H.h1 "Export"
                                  H.ul $ do H.li $ H.a ! A.href (stringValue ((show (classIdentifier x)) ++ "?format=haskell")) $ "Haskell" 
                                            H.li $ H.a ! A.href (stringValue ((show (classIdentifier x)) ++ "?format=haskell-boot")) $ "Haskell-Boot" 
                                H.div ! A.id "description" $ do
                                  H.h1 "Description"
                                  H.div ! class_ "annotation" $ a
                                H.div ! A.id "structure" $ do
                                  H.h1 "Structure"
                                  H.table $ do
                                    H.tr $ td ! colspan "3" ! class_ "type large" $ do H.a ! A.href "" $ string $ show (className x)
                                                                                       preEscapedString "&nbsp;"
                                                                                       mconcat (Data.List.intersperse (preEscapedString "&nbsp;") bv)
                                    H.tr $ td ! colspan "3" ! class_ "constraints" $ b
                                    mconcat ms
  --}
