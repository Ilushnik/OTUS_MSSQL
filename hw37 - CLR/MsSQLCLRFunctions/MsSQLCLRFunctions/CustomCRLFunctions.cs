using Microsoft.SqlServer.Server;
using System;
using System.Collections;
using System.Data.SqlTypes;

namespace MsSQLCLRFunctions
{
    public class CustomCRLFunctions
    {
        public static string SayHelloFunction(string name)
        {
            return "Hello, " + name;
        }


        [SqlFunction(FillRowMethodName = "FillRow", TableDefinition = "Value NVARCHAR(MAX)")]
        public static IEnumerable SplitString(SqlString inputString, SqlString delimiter)
        {
            if (inputString.IsNull || delimiter.IsNull)
            {
                yield break; 
            }

            string[] parts = inputString.Value.Split(new string[] { delimiter.Value }, StringSplitOptions.None);

            foreach (var part in parts)
            {
                yield return part; 
            }
        }

        public static void FillRow(object obj, out string result)
        {
            result = (string)obj; 
        }



    }

}
