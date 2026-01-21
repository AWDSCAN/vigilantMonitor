package models

// CommandTask represents a command execution task
type CommandTask struct {
	ID            uint64          `json:"id" gorm:"primaryKey;autoIncrement"`
	TaskID        string          `json:"task_id" gorm:"type:varchar(36);uniqueIndex:idx_task_id;not null"`
	Command       string          `json:"command" gorm:"type:text;not null"`
	TargetOS      string          `json:"target_os" gorm:"type:varchar(20);comment:'windows, linux, or null for all'"`
	TargetClients StringArray     `json:"target_clients" gorm:"type:longtext;comment:'JSON array of client UUIDs, null for all clients'"`
	Status        string          `json:"status" gorm:"type:varchar(20);index:idx_status;default:'pending';comment:'pending, running, completed, failed'"`
	CreatedBy     string          `json:"created_by" gorm:"type:varchar(36);comment:'user ID'"`
	TotalClients  int             `json:"total_clients" gorm:"type:int;default:0;comment:'total number of target clients'"`
	SuccessCount  int             `json:"success_count" gorm:"type:int;default:0;comment:'number of successful executions'"`
	FailedCount   int             `json:"failed_count" gorm:"type:int;default:0;comment:'number of failed executions'"`
	CreatedAt     LocalTime       `json:"created_at" gorm:"type:datetime(3)"`
	UpdatedAt     LocalTime       `json:"updated_at" gorm:"type:datetime(3)"`
	Results       []CommandResult `json:"results,omitempty" gorm:"foreignKey:TaskID;references:TaskID;constraint:OnDelete:CASCADE"`
}

func (CommandTask) TableName() string {
	return "command_tasks"
}

// CommandResult represents the execution result from a single client
type CommandResult struct {
	ID           uint64     `json:"id" gorm:"primaryKey;autoIncrement"`
	TaskID       string     `json:"task_id" gorm:"type:varchar(36);index:idx_task_id;not null"`
	ClientUUID   string     `json:"client_uuid" gorm:"type:varchar(36);index:idx_client_uuid;not null"`
	ClientInfo   *Client    `json:"client_info,omitempty" gorm:"foreignKey:ClientUUID;references:UUID"`
	Executed     bool       `json:"executed" gorm:"type:tinyint(1);default:0;comment:'whether the command was executed'"`
	Output       string     `json:"output" gorm:"type:longtext;comment:'command output'"`
	ExitCode     *int       `json:"exit_code" gorm:"type:int"`
	ErrorMessage string     `json:"error_message" gorm:"type:text;comment:'error message if execution failed'"`
	ExecutedAt   *LocalTime `json:"executed_at" gorm:"type:datetime(3);index:idx_executed_at;comment:'when the command was executed'"`
	CreatedAt    LocalTime  `json:"created_at" gorm:"type:datetime(3)"`
}

func (CommandResult) TableName() string {
	return "command_results"
}
