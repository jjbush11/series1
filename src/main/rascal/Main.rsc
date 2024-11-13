module Main

import IO;
import lang::java::m3::Core;
import lang::java::m3::AST;
import List;
import Set;
import String;

import List;
import IO;



void main(int testArgument=0) {
    asts = getASTs(|cwd://testProject0|);

    print(calculateVolumeMetric(getLOC(asts)));

    return;
}


list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}


int getLOC(list[Declaration] asts) {

    list[loc] locs = [];

    visit (asts) {
            case node n: if (n.src ?) locs += n.src;
    }
    set[tuple[loc, int]] linenrs = {<myloc.top, myloc.begin.line> , <myloc.top, myloc.end.line> | myloc <- locs};

    return(size(linenrs));
}

str calculateVolumeMetric(int amountOfLines) {
    if (amountOfLines > 1000) {
        return "--";
    }
    else { return "++"; }
}
