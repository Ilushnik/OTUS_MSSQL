using Microsoft.SqlServer.Server;
using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace MsSQLCLRFunctions
{
    [Serializable]
    [SqlUserDefinedAggregate(Format.UserDefined,
    Name = "StringAggregator",              // name of the aggregate
    MaxByteSize = 8000
    )]
    public struct StringAggregator : IBinarySerialize
    {
        private SqlString _result;
        private SqlString _delimiter;

        // Initialize the aggregation, set the initial state
        public void Init()
        {
            _result = new SqlString( string.Empty);
            _delimiter =new SqlString( ", "); // Default delimiter (this can be customized)
        }

        // Accumulate the string values from each row
        public void Accumulate(SqlString value)
        {
            if (value.IsNull) return;

            // If the result is empty, add the first value, otherwise append the delimiter and value
            if (_result == string.Empty)
            {
                _result = value.Value;
            }
            else
            {
                _result += _delimiter + value.Value;
            }
        }

        // Merge two aggregates (useful for parallel execution)
        public void Merge(StringAggregator other)
        {
            if (other._result == string.Empty) return;

            if (_result == string.Empty)
            {
                _result = other._result;
            }
            else
            {
                _result += _delimiter + other._result;
            }
        }

        // Return the final result of the aggregation
        public string Terminate()
        {
            return _result.ToString();
        }

        public void Write(BinaryWriter writer)
        {
            writer.Write(_result.IsNull ? string.Empty : _result.Value);  // Write the result as a string
            writer.Write(_delimiter.Value);  // Write the delimiter
        }

        public void Read(BinaryReader reader)
        {
            _result = new SqlString(reader.ReadString());  // Read the result as a SqlString
            _delimiter = reader.ReadString();  // Read the delimiter
        }
    }
}
