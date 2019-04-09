import Control.Monad (void, when)
import Distribution.Simple
import Distribution.Simple.Setup (BuildFlags, fromFlagOrDefault, buildDistPref)
import Distribution.PackageDescription (HookedBuildInfo, emptyHookedBuildInfo)
import System.Process (system)
import System.Directory (doesFileExist, createDirectoryIfMissing)
import System.FilePath ((</>))

main :: IO ()
main = defaultMainWithHooks $ simpleUserHooks { preBuild = maybeRunC2HS }

-- Because of a problem with Cabal dependency resolution of .chs
-- files, we need to execute C2HS manually on these two files
maybeRunC2HS :: Args -> BuildFlags -> IO HookedBuildInfo
maybeRunC2HS _args flags = do
    chiExists <- doesFileExist chiFile
    when (not chiExists) $ do
      let c2hs_args = ["c2hs",
                       "--output-dir=" ++ buildDir,
                       "--include=" ++ buildDir,
                       "--cppopts=-Iinclude --cppopts=-U__BLOCKS__",
                       chsFile]
      createDirectoryIfMissing True internalDir
      void $ system $ unwords c2hs_args
    return emptyHookedBuildInfo
  where
    distDir = fromFlagOrDefault "dist" (buildDistPref flags)
    buildDir = distDir </> "build"
    internalDir = buildDir </> "Foreign/OpenCL/Bindings/Internal"
    chiFile = internalDir </> "Types.chi"
    chsFile = "Foreign/OpenCL/Bindings/Internal/Types.chs"
