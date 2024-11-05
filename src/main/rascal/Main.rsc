module Main

import IO;
import lang::java::m3::Core;
import lang::java::m3::AST;
import util::Math;
import Map;



int main(int testArgument=0) {
    println("argument: <testArgument>");
    loc projectLocation = |cwd:///testProject0/|;
    println(getASTs(projectLocation));
    return testArgument;
}


list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
    | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

int getNumberOfInterfaces(list[Declaration] asts){
    int interfaces = 0;
    visit(asts){
    case \interface(_, _, _, _): interfaces += 1;
    }
    return interfaces;
}

// int getLOC(list [Declaration] asts) {
//     int loc = 0;
    
// }